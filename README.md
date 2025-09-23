# IndoLearn Flashcards — Database

This repository folder provides a fully automated PostgreSQL setup and seeding workflow suitable for Kavia CI/CD without any Supabase requirements.

Highlights:
- Pure PostgreSQL schema and demo seed (no RLS, no Supabase-specific features)
- Non-interactive, idempotent setup
- One-line psql connection from db_connection.txt

How to use:
1) Create `flashcards_database/db_connection.txt` containing a single line:
   psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME

2) Run:
   bash flashcards_database/setup_and_seed.sh

Details:
- See `flashcards_database/README.POSTGRES.md` for full instructions.
- Supabase-specific docs remain in `assets/supabase.md` for projects that use Supabase. This project now supports both approaches; this folder covers native PostgreSQL only.