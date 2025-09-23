# Required: db_connection.txt for Seeding

This project step needs a CLI connection command to the PostgreSQL instance.

Please create a file in this folder named `db_connection.txt` with a single line containing the psql connection command:

Example:
psql postgresql://USER:PASSWORD@HOST:PORT/DBNAME

Notes:
- The command must be usable as-is in non-interactive mode.
- It must connect to the database that already contains the schema compatible with `database_backup.sql` (tables like `word_lists`, `flashcards`, etc.).
- Do not include quotes; a single line is expected.

Once `db_connection.txt` is present, the seeding step will:
1) Insert a `word_lists` record for the Indonesian 1500 words list.
2) Insert categories if required by the provided list.
3) Insert `flashcards` entries, one INSERT per statement, referencing the created `list_id`.

This file exists only to document the requirement for the CI process and future agents.
