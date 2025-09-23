#!/usr/bin/env bash
# Automated PostgreSQL schema creation and demo data seeding for IndoLearn Flashcards.
# This script:
#  - Reads the CLI connection from db_connection.txt (single-line psql URL command)
#  - Creates required extensions (citext, pgcrypto)
#  - Creates tables: users, word_lists, categories, flashcards, quizzes, quiz_attempts, review_logs, user_flashcards
#  - Inserts demo/mock data for a minimal working dataset
#  - Runs each SQL statement individually via "psql -c" to be non-interactive and CI-friendly.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONN_FILE="${ROOT_DIR}/db_connection.txt"

if [[ ! -f "${CONN_FILE}" ]]; then
  echo "ERROR: db_connection.txt not found at ${CONN_FILE}"
  echo "Please create a file with a single line like:"
  echo "psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME"
  exit 1
fi

# Read the psql connection command (must be one line like: psql postgresql://...)
PSQL_CMD="$(cat "${CONN_FILE}" | tr -d '\r' | tail -n 1)"

# Basic check
if [[ "${PSQL_CMD}" != psql* ]]; then
  echo "ERROR: db_connection.txt must start with 'psql ' followed by the connection URI."
  exit 1
fi

# Helper to run one SQL statement in a single -c call
run_sql() {
  local sql="$1"
  ${PSQL_CMD} -v ON_ERROR_STOP=1 -q -c "${sql}"
}

echo "== IndoLearn Flashcards: PostgreSQL setup and seed =="

echo "Creating required extensions (if not exists)..."
run_sql "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"
run_sql "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;"

echo "Creating tables (if not exists)..."

# users
run_sql "CREATE TABLE IF NOT EXISTS public.users (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email public.citext NOT NULL UNIQUE,
  username varchar(50) UNIQUE,
  password_hash text,
  auth_provider varchar(20) NOT NULL DEFAULT 'local',
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);"

# word_lists
run_sql "CREATE TABLE IF NOT EXISTS public.word_lists (
  id SERIAL PRIMARY KEY,
  name text NOT NULL,
  description text,
  language_from text NOT NULL DEFAULT 'en',
  language_to text NOT NULL DEFAULT 'id',
  source text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT word_lists_name_language_from_language_to_key UNIQUE (name, language_from, language_to)
);"

# categories
run_sql "CREATE TABLE IF NOT EXISTS public.categories (
  id SERIAL PRIMARY KEY,
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  description text,
  parent_id integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);"
run_sql "ALTER TABLE public.categories
  ADD CONSTRAINT IF NOT EXISTS categories_parent_id_fkey
  FOREIGN KEY (parent_id) REFERENCES public.categories(id) ON DELETE SET NULL;"

# flashcards
run_sql "CREATE TABLE IF NOT EXISTS public.flashcards (
  id SERIAL PRIMARY KEY,
  list_id integer REFERENCES public.word_lists(id) ON DELETE CASCADE,
  category_id integer REFERENCES public.categories(id) ON DELETE SET NULL,
  base_word text NOT NULL,
  translation text NOT NULL,
  pos text,
  example_sentence text,
  example_translation text,
  difficulty smallint NOT NULL DEFAULT 1,
  tags text[],
  audio_url text,
  extra jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT flashcards_list_id_base_word_translation_key UNIQUE (list_id, base_word, translation)
);"
run_sql "CREATE INDEX IF NOT EXISTS idx_flashcards_list_category ON public.flashcards (list_id, category_id);"

# quizzes
run_sql "CREATE TABLE IF NOT EXISTS public.quizzes (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  mode text NOT NULL,
  direction smallint NOT NULL DEFAULT 0,
  category_id integer REFERENCES public.categories(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);"

# quiz_attempts
run_sql "CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id BIGSERIAL PRIMARY KEY,
  quiz_id bigint REFERENCES public.quizzes(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  card_id integer REFERENCES public.flashcards(id) ON DELETE CASCADE,
  is_correct boolean NOT NULL,
  choice_a text,
  choice_b text,
  choice_c text,
  choice_d text,
  correct_choice char(1),
  response_choice char(1),
  response_time_ms integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT quiz_attempts_quiz_id_card_id_key UNIQUE (quiz_id, card_id)
);"
run_sql "CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz ON public.quiz_attempts (quiz_id);"

# review_logs
run_sql "CREATE TABLE IF NOT EXISTS public.review_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  card_id integer REFERENCES public.flashcards(id) ON DELETE CASCADE,
  direction smallint NOT NULL DEFAULT 0,
  rating smallint NOT NULL,
  prev_ease numeric(4,2),
  new_ease numeric(4,2),
  prev_interval integer,
  new_interval integer,
  reviewed_at timestamptz NOT NULL DEFAULT now()
);"
run_sql "CREATE INDEX IF NOT EXISTS idx_review_logs_user_card
  ON public.review_logs (user_id, card_id, reviewed_at DESC);"

# user_flashcards
run_sql "CREATE TABLE IF NOT EXISTS public.user_flashcards (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  card_id integer REFERENCES public.flashcards(id) ON DELETE CASCADE,
  direction smallint NOT NULL DEFAULT 0,
  last_reviewed_at timestamptz,
  next_review_at timestamptz,
  ease_factor numeric(4,2) NOT NULL DEFAULT 2.50,
  interval_days integer NOT NULL DEFAULT 0,
  reps integer NOT NULL DEFAULT 0,
  lapses integer NOT NULL DEFAULT 0,
  status smallint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_flashcards_user_id_card_id_direction_key UNIQUE (user_id, card_id, direction)
);"
run_sql "CREATE INDEX IF NOT EXISTS idx_user_flashcards_due
  ON public.user_flashcards (user_id, next_review_at) WHERE status IN (1,2);"

echo "Inserting demo data (idempotent upserts)..."

# Demo user (local auth)
# Using a fixed UUID to make idempotent; change if needed.
DEMO_USER_ID="a5a3f0c6-1111-4b22-9a33-5f2ce2f2abcd"
run_sql "INSERT INTO public.users (id, email, username, password_hash, auth_provider)
VALUES ('${DEMO_USER_ID}', 'demo1@example.com', 'demo1', NULL, 'local')
ON CONFLICT (email) DO UPDATE SET updated_at = now();"

# Categories
run_sql "INSERT INTO public.categories (slug, name, description)
VALUES
  ('common', 'Common', 'Common words'),
  ('verbs', 'Verbs', 'Action words'),
  ('nouns', 'Nouns', 'Noun category')
ON CONFLICT (slug) DO NOTHING;"

# Word list
run_sql \"INSERT INTO public.word_lists (name, description, language_from, language_to, source)
VALUES ('Indonesian 1500', 'Most common Indonesian words', 'en', 'id', 'demo seed')
ON CONFLICT (name, language_from, language_to) DO UPDATE SET updated_at = now();\"

# Resolve IDs
# Get list_id
LIST_ID="$(${PSQL_CMD} -t -A -q -c \"SELECT id FROM public.word_lists WHERE name='Indonesian 1500' AND language_from='en' AND language_to='id' LIMIT 1;\")"
# Get category ids
CAT_COMMON="$(${PSQL_CMD} -t -A -q -c \"SELECT id FROM public.categories WHERE slug='common' LIMIT 1;\")"
CAT_VERBS="$(${PSQL_CMD} -t -A -q -c \"SELECT id FROM public.categories WHERE slug='verbs' LIMIT 1;\")"
CAT_NOUNS="$(${PSQL_CMD} -t -A -q -c \"SELECT id FROM public.categories WHERE slug='nouns' LIMIT 1;\")"

trim() { echo "$1" | tr -d ' \t\n\r'; }
LIST_ID="$(trim "${LIST_ID}")"
CAT_COMMON="$(trim "${CAT_COMMON}")"
CAT_VERBS="$(trim "${CAT_VERBS}")"
CAT_NOUNS="$(trim "${CAT_NOUNS}")"

if [[ -z "${LIST_ID}" ]]; then
  echo "ERROR: Could not resolve word list id for 'Indonesian 1500'."
  exit 1
fi

# Insert a few flashcards (idempotent on (list_id, base_word, translation))
run_sql "INSERT INTO public.flashcards (list_id, category_id, base_word, translation, pos, difficulty)
VALUES
  (${LIST_ID}, ${CAT_NOUNS:-null}, 'house', 'rumah', 'noun', 1),
  (${LIST_ID}, ${CAT_VERBS:-null}, 'eat', 'makan', 'verb', 1),
  (${LIST_ID}, ${CAT_COMMON:-null}, 'good', 'baik', null, 1),
  (${LIST_ID}, ${CAT_NOUNS:-null}, 'water', 'air', 'noun', 1),
  (${LIST_ID}, ${CAT_VERBS:-null}, 'go', 'pergi', 'verb', 1)
ON CONFLICT (list_id, base_word, translation) DO NOTHING;"

# Create a demo quiz for demo user, direction 0, mode 'multiple_choice'
QUIZ_ID="$(${PSQL_CMD} -t -A -q -c \"INSERT INTO public.quizzes (user_id, mode, direction, category_id)
VALUES ('${DEMO_USER_ID}', 'multiple_choice', 0, ${CAT_COMMON:-null})
RETURNING id;\")" || true

QUIZ_ID="$(trim "${QUIZ_ID}")"

if [[ -z "${QUIZ_ID}" ]]; then
  # If insert failed due to duplicates or other, pick most recent quiz for the user
  QUIZ_ID="$(${PSQL_CMD} -t -A -q -c \"SELECT id FROM public.quizzes WHERE user_id='${DEMO_USER_ID}' ORDER BY created_at DESC LIMIT 1;\")"
  QUIZ_ID="$(trim "${QUIZ_ID}")"
fi

# Grab some card ids for attempts
CARD_IDS="$(${PSQL_CMD} -t -A -q -c \"SELECT id FROM public.flashcards WHERE list_id=${LIST_ID} ORDER BY id LIMIT 3;\")"
CARD1="$(echo "${CARD_IDS}" | sed -n '1p')"; CARD1="$(trim "${CARD1:-}")"
CARD2="$(echo "${CARD_IDS}" | sed -n '2p')"; CARD2="$(trim "${CARD2:-}")"
CARD3="$(echo "${CARD_IDS}" | sed -n '3p')"; CARD3="$(trim "${CARD3:-}")"

# Insert a couple of quiz attempts if we have quiz and cards
if [[ -n "${QUIZ_ID}" && -n "${CARD1}" ]]; then
  # Attempt entries (choose A-D randomly-ish)
  run_sql "INSERT INTO public.quiz_attempts
    (quiz_id, user_id, card_id, is_correct, choice_a, choice_b, choice_c, choice_d, correct_choice, response_choice, response_time_ms)
  VALUES
    (${QUIZ_ID}, '${DEMO_USER_ID}', ${CARD1}, true,  'rumah','makan','baik','air','A','A',1200)
  ON CONFLICT (quiz_id, card_id) DO NOTHING;"

  if [[ -n "${CARD2}" ]]; then
    run_sql "INSERT INTO public.quiz_attempts
      (quiz_id, user_id, card_id, is_correct, choice_a, choice_b, choice_c, choice_d, correct_choice, response_choice, response_time_ms)
    VALUES
      (${QUIZ_ID}, '${DEMO_USER_ID}', ${CARD2}, false, 'rumah','makan','baik','air','B','A',2100)
    ON CONFLICT (quiz_id, card_id) DO NOTHING;"
  fi

  if [[ -n "${CARD3}" ]]; then
    run_sql "INSERT INTO public.quiz_attempts
      (quiz_id, user_id, card_id, is_correct, choice_a, choice_b, choice_c, choice_d, correct_choice, response_choice, response_time_ms)
    VALUES
      (${QUIZ_ID}, '${DEMO_USER_ID}', ${CARD3}, true,  'air','pergi','baik','makan','A','A',1500)
    ON CONFLICT (quiz_id, card_id) DO NOTHING;"
  fi
fi

# Insert one review log and one user_flashcard entry
if [[ -n "${CARD1}" ]]; then
  run_sql "INSERT INTO public.review_logs
    (user_id, card_id, direction, rating, prev_ease, new_ease, prev_interval, new_interval)
  VALUES ('${DEMO_USER_ID}', ${CARD1}, 0, 4, 2.50, 2.60, 0, 1);"

  run_sql "INSERT INTO public.user_flashcards
    (user_id, card_id, direction, last_reviewed_at, next_review_at, ease_factor, interval_days, reps, lapses, status)
  VALUES ('${DEMO_USER_ID}', ${CARD1}, 0, now(), now() + interval '1 day', 2.60, 1, 1, 0, 1)
  ON CONFLICT (user_id, card_id, direction) DO NOTHING;"
fi

echo "== Setup and seeding complete =="
echo "Verification tips:"
echo "  - ${PSQL_CMD} -c \"SELECT COUNT(*) FROM public.flashcards;\""
echo "  - ${PSQL_CMD} -c \"SELECT * FROM public.quizzes ORDER BY created_at DESC LIMIT 1;\""
echo "  - ${PSQL_CMD} -c \"SELECT * FROM public.user_flashcards LIMIT 1;\""
