-- Supabase seed script template for Indonesian 1500 word list
-- This script is intended to be executed via SupabaseTool_run_sql by the automation agent.

-- 1) Ensure word list exists and capture the id
WITH upsert_list AS (
  INSERT INTO public.word_lists (name, description, language_from, language_to, source)
  VALUES ('Indonesian 1500', 'Most common 1500 Indonesian words', 'en', 'id', 'project seed')
  ON CONFLICT (name, language_from, language_to) DO UPDATE
    SET updated_at = now()
  RETURNING id
)
SELECT id FROM upsert_list;

-- 2) Optional: Ensure a base "common" category exists
INSERT INTO public.categories (slug, name, description)
VALUES ('common', 'Common', 'Common words')
ON CONFLICT (slug) DO NOTHING;

-- 3) Insert flashcards: Replace the sample rows with actual data rows
-- The agent will dynamically resolve the list_id before inserts if needed.
-- Example rows (to be replaced by actual dataset):
-- INSERT INTO public.flashcards (list_id, category_id, base_word, translation, pos, difficulty)
-- SELECT wl.id, c.id, 'house', 'rumah', 'noun', 1
-- FROM public.word_lists wl
-- LEFT JOIN public.categories c ON c.slug = 'common'
-- WHERE wl.name = 'Indonesian 1500' AND wl.language_from = 'en' AND wl.language_to = 'id';

-- Repeat the above INSERT for each word pair (or use a VALUES block).
