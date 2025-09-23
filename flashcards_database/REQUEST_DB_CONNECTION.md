# Required: db_connection.txt

To run the automated setup and seeding, create a file `db_connection.txt` in this folder with a single line containing the psql connection command:

Example:
psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME

Requirements:
- Must be non-interactive and usable in CI (no prompts).
- Points to the target database to create schema and seed demo data.
- Do not include quotes; a single line is expected.

Then run:
bash setup_and_seed.sh

The script will:
- Create required extensions (citext, pgcrypto)
- Create/update tables (users, word_lists, categories, flashcards, quizzes, quiz_attempts, review_logs, user_flashcards)
- Seed demo data (users, categories, word list, flashcards, a quiz, a few quiz_attempts, at least one review_log and user_flashcard)
