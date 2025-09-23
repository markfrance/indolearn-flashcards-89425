# Seeding via Supabase (Active)

Local seeding is deprecated. Use Supabase.

Steps for automation agent (requires env variables present in container):
1. SupabaseTool_list_tables to verify tables
2. SupabaseTool_run_sql to:
   - Upsert the 'Indonesian 1500' word list and capture list_id
   - Optionally create categories (e.g., 'common')
   - Insert flashcards rows for the list

The agent uses environment variables:
- SUPABASE_URL
- SUPABASE_KEY (service_role) or SUPABASE_ANON_KEY

If these are not present, agent will stop with a partial completion and request they be added.

See ../../assets/supabase.md for the exact SQL plan and variable names required.
