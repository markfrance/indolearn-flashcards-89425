#!/usr/bin/env bash
set -euo pipefail

# Ensure postgres is up and db_connection.txt exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "${SCRIPT_DIR}/db_connection.txt" ]; then
  echo "db_connection.txt not found. Starting DB..."
  bash "${SCRIPT_DIR}/startup.sh"
fi

echo "Seeding Indonesian 1500 Core data..."
python3 "${SCRIPT_DIR}/seed_indonesian_1500.py"
echo "Seeding complete."
