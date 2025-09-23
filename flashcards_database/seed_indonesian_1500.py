#!/usr/bin/env python3
"""
Seed script for Indonesian 1500 core flashcards.

- Reads the PostgreSQL CLI connection command from db_connection.txt (e.g., "psql postgresql://...").
- Creates or updates a word_lists entry with name = 'Indonesian 1500 Core' and source attribution.
- Parses data/indonesian_1500_draft.csv (rank,surface_word,base_form,zipf,kept_reason,gloss_en,notes,attribution).
- Inserts each flashcard into public.flashcards with:
    list_id = the word_list id (looked up by unique constraint)
    base_word = base_form if available else surface_word
    translation = gloss_en
    pos, example_sentence, example_translation, tags, audio_url left NULL
    extra jsonb contains source fields (rank, zipf, kept_reason, notes, surface_word, attribution)
- Omits prefixed words unless semantic difference is documented: we insert only one per base_word+translation due to UNIQUE(list_id, base_word, translation).
- Executes SQL statements one at a time via the SQL CLI, escaping safely using $$ dollar-quoting.
- Idempotent: uses ON CONFLICT DO NOTHING for flashcards and upserts word_list by unique key.
"""

import csv
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
DB_DIR = Path(__file__).resolve().parent
DATA_CSV = BASE_DIR / "data" / "indonesian_1500_draft.csv"
DB_CONN_FILE = DB_DIR / "db_connection.txt"

WORDLIST_NAME = "Indonesian 1500 Core"
WORDLIST_DESC = (
    "Curated 1500 most common Indonesian words suitable for learners. "
    "See kavia-docs/indonesian_1500_word_sources.md and data/README.md for process and licenses."
)
WORDLIST_LANG_FROM = "en"
WORDLIST_LANG_TO = "id"
WORDLIST_SOURCE = (
    "Frequencies via wordfreq (CC BY-SA 4.0); Stemming via Sastrawi (MIT). "
    "Curation notes in kavia-docs/indonesian_1500_word_sources.md"
)

def run_psql(sql: str, psql_cmd: str) -> subprocess.CompletedProcess:
    """
    Runs a single SQL statement through psql in non-interactive mode,
    using -v ON_ERROR_STOP=1 and -c "..." exact statement.
    """
    # Use dollar-quoting to avoid escaping of single quotes
    sql_wrapped = f"DO $$BEGIN END$$; {sql}" if False else sql  # placeholder to keep sql as single statement
    cmd = f'{psql_cmd} -v ON_ERROR_STOP=1 -c {shlex.quote(sql_wrapped)}'
    # We don't pass sql on stdin to ensure one-at-a-time and avoid multiline shell quoting pitfalls.
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

def run_psql_capture(sql: str, psql_cmd: str) -> str:
    """Run SQL and return stdout, raising on error."""
    proc = run_psql(sql, psql_cmd)
    if proc.returncode != 0:
        raise RuntimeError(f"psql error ({proc.returncode}): {proc.stderr.strip()}\nSQL: {sql}")
    return proc.stdout.strip()

def ensure_word_list(psql_cmd: str) -> int:
    """
    Upsert the word list using INSERT ... ON CONFLICT by unique (name, language_from, language_to).
    Then SELECT id and return it.
    """
    insert_sql = f"""
INSERT INTO public.word_lists (name, description, language_from, language_to, source)
VALUES ($${WORDLIST_NAME}$$, $${WORDLIST_DESC}$$, $${WORDLIST_LANG_FROM}$$, $${WORDLIST_LANG_TO}$$, $${WORDLIST_SOURCE}$$)
ON CONFLICT (name, language_from, language_to)
DO UPDATE SET updated_at = now(), source = EXCLUDED.source;
""".strip()
    out = run_psql_capture(insert_sql, psql_cmd)

    select_sql = f"""
SELECT id FROM public.word_lists
WHERE name = $${WORDLIST_NAME}$$ AND language_from = $${WORDLIST_LANG_FROM}$$ AND language_to = $${WORDLIST_LANG_TO}$$;
""".strip()
    out = run_psql_capture(select_sql, psql_cmd)
    # psql prints a header and result unless -At is used. We will re-run with -At for deterministic single value.
    cmd = f"{psql_cmd} -At -c {shlex.quote(select_sql)}"
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"psql select error: {proc.stderr}")
    val = proc.stdout.strip()
    if not val or not val.isdigit():
        raise RuntimeError(f"Unexpected id result: {val}")
    return int(val)

def build_flashcard_insert(list_id: int, base_word: str, translation: str, extra_obj: dict) -> str:
    """
    Builds a single INSERT for public.flashcards with ON CONFLICT DO NOTHING.
    Uses dollar-quoting for safety.
    Only inserts minimal required fields, leaving others as NULL/defaults.
    """
    # Normalize base_word and translation
    bw = (base_word or "").strip()
    tr = (translation or "").strip()
    if not bw or not tr:
        return ""

    extra_json = json.dumps(extra_obj, ensure_ascii=False)
    sql = f"""
INSERT INTO public.flashcards (list_id, base_word, translation, extra)
VALUES ({list_id}, $${bw}$$, $${tr}$$, $${extra_json}$$::jsonb)
ON CONFLICT (list_id, base_word, translation) DO NOTHING;
""".strip()
    return sql

def main():
    if not DB_CONN_FILE.exists():
        print(f"ERROR: db_connection.txt not found at {DB_CONN_FILE}", file=sys.stderr)
        sys.exit(1)
    psql_cmd = DB_CONN_FILE.read_text().strip()
    if not psql_cmd.startswith("psql "):
        print("ERROR: db_connection.txt does not contain a psql command.", file=sys.stderr)
        sys.exit(1)

    if not DATA_CSV.exists():
        print(f"ERROR: data CSV not found at {DATA_CSV}", file=sys.stderr)
        sys.exit(1)

    # Quick connectivity check
    test_proc = subprocess.run(f"{psql_cmd} -At -c 'SELECT 1;'", shell=True, capture_output=True, text=True)
    if test_proc.returncode != 0:
        print(f"ERROR: Cannot connect to Postgres: {test_proc.stderr}", file=sys.stderr)
        sys.exit(1)

    # Ensure word list
    list_id = ensure_word_list(psql_cmd)
    print(f"Word list id: {list_id}")

    inserted = 0
    skipped = 0
    with DATA_CSV.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Expected headers: rank,surface_word,base_form,zipf,kept_reason,gloss_en,notes,attribution
            surface = (row.get("surface_word") or "").strip()
            base = (row.get("base_form") or "").strip()
            translation = (row.get("gloss_en") or "").strip()
            kept_reason = (row.get("kept_reason") or "").strip()
            notes = (row.get("notes") or "").strip()
            zipf = row.get("zipf") or ""
            attribution = (row.get("attribution") or "").strip()
            rank = (row.get("rank") or "").strip()

            base_word = base or surface

            # Morphology handling: if surface differs only by prefix and no semantic diff documented, base handles it.
            # This is approximated by the unique constraint (list_id, base_word, translation).

            extra = {
                "rank": rank,
                "surface_word": surface,
                "zipf": zipf,
                "kept_reason": kept_reason,
                "notes": notes,
                "attribution": attribution
            }

            sql = build_flashcard_insert(list_id, base_word, translation, extra)
            if not sql:
                skipped += 1
                continue

            proc = run_psql(sql, psql_cmd)
            if proc.returncode != 0:
                # Log and continue; we insert records one at a time.
                print(f"Warn: failed to insert '{base_word}' => '{translation}': {proc.stderr.strip()}", file=sys.stderr)
                skipped += 1
                continue
            else:
                inserted += 1
                if inserted % 100 == 0:
                    print(f"Inserted {inserted} records...")

    print(f"Done. Inserted: {inserted}, Skipped: {skipped}")

if __name__ == "__main__":
    main()
