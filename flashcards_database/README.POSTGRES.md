# PostgreSQL Setup and Seeding (No Supabase)

This folder enables fully automated setup and seeding of a native PostgreSQL database for IndoLearn Flashcards on Kavia.

What this provides:
- Standard PostgreSQL schema (no Supabase-specific features)
- Tables: users, word_lists, categories, flashcards, quizzes, quiz_attempts, review_logs, user_flashcards
- Idempotent demo data seeding: user, categories, a word list, a few flashcards, one quiz with attempts, one review log, and one user_flashcard
- CSV-based seeding for the "Indonesian 1500" word list (English → Indonesian) via a dedicated script

Quick start:
1) Provide connection:
   Create db_connection.txt in this folder with a single line:
   psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME

   The URL must connect to the target database. The script will create required extensions and tables if missing.

2) Create schema (one-time or idempotent):
   bash create_core_tables.sh

3) Seed demo data (optional):
   bash setup_and_seed.sh

4) Seed the full Indonesian 1500 list from CSV:
   - Place your CSV at flashcards_database/data/indonesian_1500.csv
     or provide a custom path as the first argument.
   - Run:
     bash seed_indonesian_1500.sh [optional_path_to_csv]

   CSV format (header row required):
   english,indonesian,pos,category_slug,example_sentence,example_translation,difficulty,tags,audio_url

   Notes:
   - tags: comma-separated list (e.g., "common, beginner")
   - difficulty: integer-like value, defaults to 1 if blank
   - category_slug: defaults to "common" if blank; new slugs are auto-created

What it does:
- Reads psql connection from db_connection.txt
- Ensures extensions citext and pgcrypto exist
- Creates tables if not exists with appropriate constraints and indexes
- Inserts demo data (idempotent upserts where possible)
- CSV seeding script:
  - Loads CSV to a staging table using \copy
  - Upserts categories
  - Upserts the word list ("Indonesian 1500")
  - Inserts flashcards idempotently (unique on (list_id, base_word, translation))
- Prints simple verification commands

Notes:
- No interactive prompts; suitable for CI.
- No Supabase dependencies or RLS; this is pure PostgreSQL.
- The demo user has a fixed UUID for idempotence and easy referencing.

Verification:
- Count all flashcards:
  $(cat db_connection.txt) -c "SELECT COUNT(*) FROM public.flashcards;"
- Count flashcards for the Indonesian 1500 list:
  $(cat db_connection.txt) -c "SELECT COUNT(*) FROM public.flashcards f JOIN public.word_lists wl ON wl.id=f.list_id WHERE wl.name='Indonesian 1500' AND wl.language_from='en' AND wl.language_to='id';"
- Show latest quiz:
  $(cat db_connection.txt) -c "SELECT * FROM public.quizzes ORDER BY created_at DESC LIMIT 1;"
- Check user_flashcards:
  $(cat db_connection.txt) -c "SELECT * FROM public.user_flashcards LIMIT 1;"
