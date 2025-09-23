# Database Seeding: Indonesian 1500 Core

This script seeds the PostgreSQL database with the curated Indonesian 1500 word list.

What it does:
- Reads the psql CLI connection from flashcards_database/db_connection.txt (created by startup.sh).
- Creates or updates the word list entry:
  - name: Indonesian 1500 Core
  - language_from: en
  - language_to: id
  - source: Frequencies via wordfreq (CC BY-SA 4.0); Stemming via Sastrawi (MIT). Curation notes in kavia-docs/indonesian_1500_word_sources.md
- Inserts each flashcard, one SQL statement at a time, into public.flashcards. It fills extra JSON with rank, zipf, kept_reason, notes, surface_word, attribution.

CSV input:
- Path: data/indonesian_1500_draft.csv (at repo root)
- Headers: rank,surface_word,base_form,zipf,kept_reason,gloss_en,notes,attribution

Morphology handling:
- Prefixed forms are folded into their base form unless the CSV documents semantic difference via gloss or kept_reason. The DB UNIQUE (list_id, base_word, translation) prevents duplicates.

How to run:
1) Ensure PostgreSQL is running and db_connection.txt exists:
   - cd indolearn-flashcards-89425/flashcards_database
   - ./startup.sh
2) Seed:
   - python3 indolearn-flashcards-89425/flashcards_database/seed_indonesian_1500.py

Verification:
- Use the included viewer or psql:
  - psql … -c "SELECT count(*) FROM public.flashcards;"
  - psql … -c "SELECT * FROM public.word_lists WHERE name = 'Indonesian 1500 Core';"

Notes:
- Source attribution docs are in kavia-docs/indonesian_1500_word_sources.md and data/README.md at repo root.
- Environment variables (for other containers): NEXT_PUBLIC_NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_NEXT_PUBLIC_SUPABASE_ANON_KEY
