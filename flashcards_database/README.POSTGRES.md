# PostgreSQL Setup and Seeding (No Supabase)

This folder enables fully automated setup and seeding of a native PostgreSQL database for IndoLearn Flashcards on Kavia.

What this provides:
- Standard PostgreSQL schema (no Supabase-specific features)
- Tables: users, word_lists, categories, flashcards, quizzes, quiz_attempts, review_logs, user_flashcards
- Idempotent demo data seeding: user, categories, a word list, a few flashcards, one quiz with attempts, one review log, and one user_flashcard

Quick start:
1) Provide connection:
   Create db_connection.txt in this folder with a single line:
   psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME

   The URL must connect to the target database. The script will create required extensions and tables if missing.

2) Run the script:
   bash setup_and_seed.sh

What it does:
- Reads psql connection from db_connection.txt
- Ensures extensions citext and pgcrypto exist
- Creates tables if not exists with appropriate constraints and indexes
- Inserts demo data (idempotent upserts where possible)
- Prints simple verification commands

Notes:
- No interactive prompts; suitable for CI.
- No Supabase dependencies or RLS; this is pure PostgreSQL.
- The demo user has a fixed UUID for idempotence and easy referencing.

Verification:
- Count flashcards:
  $(cat db_connection.txt) -c "SELECT COUNT(*) FROM public.flashcards;"
- Show latest quiz:
  $(cat db_connection.txt) -c "SELECT * FROM public.quizzes ORDER BY created_at DESC LIMIT 1;"
- Check user_flashcards:
  $(cat db_connection.txt) -c "SELECT * FROM public.user_flashcards LIMIT 1;"
