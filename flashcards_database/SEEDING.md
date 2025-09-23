# Seeding (Deprecated)

Local database seeding is no longer used. The project has migrated to Supabase.

If you need to seed data:
- Use Supabase Studio to import a CSV into the `flashcards` table, or
- Use the SQL editor in Supabase to run INSERT statements

Recommended CSV columns: `english,indonesian,part_of_speech,category_id`

See `assets/supabase.md` for the active schema and guidance. Do not run any local seed scripts from this folder.
