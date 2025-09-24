#!/usr/bin/env bash
# IndoLearn Flashcards - Indonesian 1500 Seeding Script (CSV-based)
# Purpose:
#   Seed the database with the top 1500 Indonesian words (with English translations and metadata)
#   after the core tables have been created.
#   - Reads psql CLI connection from db_connection.txt (single-line: psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME)
#   - Operates entirely via CLI (no dependencies)
#   - Imports from a CSV into a staging table, upserts categories, ensures the word list exists,
#     and inserts into public.flashcards with idempotent constraints.
#
# Usage:
#   1) Ensure core tables exist (run bash create_core_tables.sh first if needed).
#   2) Place your CSV at flashcards_database/data/indonesian_1500.csv
#      (or provide a custom path as the first argument).
#   3) Run:
#      bash seed_indonesian_1500.sh [optional_path_to_csv]
#
# CSV Format (header row required):
#   english,indonesian,pos,category_slug,example_sentence,example_translation,difficulty,tags,audio_url
# Notes:
#   - tags: comma-separated values (e.g., "common, beginner")
#   - difficulty: integer-like value (1..5 recommended), defaults to 1 if blank
#   - category_slug: if blank or missing, defaults to 'common' (auto-created if not present)
#
# Idempotency:
#   - Word list upsert on (name, language_from, language_to)
#   - Categories upsert on slug
#   - Flashcards upsert due to unique (list_id, base_word, translation)
#
# Exit codes:
#   1 - missing db_connection.txt
#   2 - invalid db_connection.txt command (must start with psql)
#   3 - CSV file not found

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
  exit 2
fi

CSV_PATH="${1:-${ROOT_DIR}/data/indonesian_1500.csv}"
if [[ ! -f "${CSV_PATH}" ]]; then
  echo "ERROR: CSV file not found at: ${CSV_PATH}"
  echo "Provide the CSV path as the first argument or place it at:"
  echo "  ${ROOT_DIR}/data/indonesian_1500.csv"
  echo "A sample file exists at: ${ROOT_DIR}/data/indonesian_1500.sample.csv"
  exit 3
fi

echo "== IndoLearn Flashcards: Seeding Indonesian 1500 from CSV =="
echo "Using connection from db_connection.txt"
echo "CSV: ${CSV_PATH}"

# Run everything in a single psql session to allow \copy and staging usage.
${PSQL_CMD} <<SQL
\set ON_ERROR_STOP on

BEGIN;

-- Ensure baseline 'common' category exists for defaulting
INSERT INTO public.categories (slug, name, description)
VALUES ('common', 'Common', 'Common words')
ON CONFLICT (slug) DO NOTHING;

-- Ensure target word list exists
INSERT INTO public.word_lists (name, description, language_from, language_to, source)
VALUES ('Indonesian 1500', 'Most common Indonesian words', 'en', 'id', 'csv import')
ON CONFLICT (name, language_from, language_to)
DO UPDATE SET updated_at = now();

-- Create a durable staging table (idempotent) and clear it
CREATE TABLE IF NOT EXISTS public.staging_indonesian_1500 (
  english              text,
  indonesian           text,
  pos                  text,
  category_slug        text,
  example_sentence     text,
  example_translation  text,
  difficulty           text,
  tags                 text,
  audio_url            text
);
TRUNCATE TABLE public.staging_indonesian_1500;

-- Bulk import from CSV using \copy (client-side). Header required.
\copy public.staging_indonesian_1500 (
  english,
  indonesian,
  pos,
  category_slug,
  example_sentence,
  example_translation,
  difficulty,
  tags,
  audio_url
) FROM '${CSV_PATH}' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"');

-- Upsert categories referenced by CSV (ignore blanks)
INSERT INTO public.categories (slug, name)
SELECT s.slug,
       initcap(replace(s.slug, '-', ' '))
FROM (
  SELECT DISTINCT NULLIF(category_slug, '') AS slug
  FROM public.staging_indonesian_1500
) s
WHERE s.slug IS NOT NULL
ON CONFLICT (slug) DO NOTHING;

-- Insert flashcards for the 'Indonesian 1500' list
-- - Uses COALESCE to default missing categories to 'common'
-- - Casts difficulty to smallint; defaults to 1 when blank
-- - Parses comma-separated tags into text[]
INSERT INTO public.flashcards
  (list_id, category_id, base_word, translation, pos, example_sentence, example_translation, difficulty, tags, audio_url)
SELECT wl.id AS list_id,
       COALESCE(c.id, (SELECT id FROM public.categories WHERE slug = 'common' LIMIT 1)) AS category_id,
       s.english AS base_word,
       s.indonesian AS translation,
       NULLIF(s.pos, '') AS pos,
       NULLIF(s.example_sentence, '') AS example_sentence,
       NULLIF(s.example_translation, '') AS example_translation,
       COALESCE(NULLIF(s.difficulty, '')::smallint, 1) AS difficulty,
       CASE
         WHEN s.tags IS NULL OR s.tags = '' THEN NULL
         ELSE regexp_split_to_array(s.tags, E'\\s*,\\s*')
       END AS tags,
       NULLIF(s.audio_url, '') AS audio_url
FROM public.staging_indonesian_1500 s
CROSS JOIN (
  SELECT id FROM public.word_lists
  WHERE name = 'Indonesian 1500' AND language_from = 'en' AND language_to = 'id'
  LIMIT 1
) AS wl
LEFT JOIN public.categories c
  ON c.slug = COALESCE(NULLIF(s.category_slug, ''), 'common')
ON CONFLICT (list_id, base_word, translation) DO NOTHING;

COMMIT;

-- Report a summary
\\echo '--- Seeding Summary ---'
SELECT
  (SELECT id FROM public.word_lists WHERE name='Indonesian 1500' AND language_from='en' AND language_to='id' LIMIT 1) AS list_id,
  (SELECT COUNT(*) FROM public.staging_indonesian_1500) AS rows_in_staging,
  (SELECT COUNT(*) FROM public.flashcards f
     JOIN public.word_lists wl ON wl.id = f.list_id
   WHERE wl.name='Indonesian 1500' AND wl.language_from='en' AND wl.language_to='id') AS total_flashcards_for_list;

SQL

echo "== Seeding complete =="
echo "Verification tips:"
echo "  - $(cat "${CONN_FILE}") -c \"SELECT COUNT(*) FROM public.flashcards f JOIN public.word_lists wl ON wl.id=f.list_id WHERE wl.name='Indonesian 1500' AND wl.language_from='en' AND wl.language_to='id';\""
echo "  - $(cat "${CONN_FILE}") -c \"SELECT base_word, translation, pos FROM public.flashcards f JOIN public.word_lists wl ON wl.id=f.list_id WHERE wl.name='Indonesian 1500' ORDER BY f.id LIMIT 10;\""
