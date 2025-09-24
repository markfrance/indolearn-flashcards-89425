#!/usr/bin/env bash
# IndoLearn Flashcards - Core Tables Creation Script
# Purpose:
#   Create the core PostgreSQL schema objects required for the app, without any seeding.
#   - Reads the CLI connection from db_connection.txt (single-line: psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME)
#   - Executes each statement individually with "psql -c" (non-interactive, CI-friendly)
#   - Creates extensions and tables:
#       users, word_lists, categories (word categories), flashcards,
#       quizzes, quiz_attempts, review_logs, user_flashcards
#   - Adds indexes and constraints suitable for efficient lookups and seeding
#
# Usage:
#   1) Create db_connection.txt with one line:
#      psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME
#   2) Run:
#      bash create_core_tables.sh
#
# Notes:
#   - No inserts are performed here (schema-only).
#   - Use setup_and_seed.sh if you want demo seed data.

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
PSQL_CMD="$(tr -d '\r' < "${CONN_FILE}" | tail -n 1)"

if [[ "${PSQL_CMD}" != psql* ]]; then
  echo "ERROR: db_connection.txt must start with 'psql ' followed by the connection URI."
  exit 1
fi

# Helper to run one SQL statement in a single -c call
run_sql() {
  local sql="$1"
  ${PSQL_CMD} -v ON_ERROR_STOP=1 -q -c "${sql}"
}

echo "== IndoLearn Flashcards: Core tables creation =="

echo "Creating required extensions (if not exists)..."
run_sql "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;"
run_sql "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;"

echo "Creating core tables and constraints (if not exists)..."

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
run_sql "CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);"

# Optional but recommended for seeding and list management
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

# word categories
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

# flashcards (Indonesian words with metadata)
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
# Fast lookup / search by base_word (simple config is adequate for Indonesian tokens)
run_sql "CREATE INDEX IF NOT EXISTS idx_flashcards_base_word ON public.flashcards USING gin (to_tsvector('simple', base_word));"

# quizzes (for grouping quiz attempts)
run_sql "CREATE TABLE IF NOT EXISTS public.quizzes (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  mode text NOT NULL,
  direction smallint NOT NULL DEFAULT 0,
  category_id integer REFERENCES public.categories(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);"

# quiz_attempts (quiz history)
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

# spaced repetition logs (per-review history)
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
run_sql "CREATE INDEX IF NOT EXISTS idx_review_logs_user_card ON public.review_logs (user_id, card_id, reviewed_at DESC);"

# spaced repetition state per user/card
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
run_sql "CREATE INDEX IF NOT EXISTS idx_user_flashcards_due ON public.user_flashcards (user_id, next_review_at) WHERE status IN (1,2);"

echo "== Core tables creation complete =="
