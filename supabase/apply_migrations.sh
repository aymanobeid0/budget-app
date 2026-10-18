#!/usr/bin/env bash
# Applies every file in supabase/migrations/ that the server has not run yet.
#
# Applied versions are recorded in supabase_migrations.schema_migrations, the
# same table the Supabase CLI uses, so each file runs once. Every migration is
# also safe to run more than once, so the first run against a server that was
# migrated by hand through Studio is harmless.
#
# PSQL is the command that opens psql on the server and reads SQL from stdin.
#   Local Docker stack:
#     PSQL="docker exec -i supabase-db psql -U postgres -d postgres" supabase/apply_migrations.sh
#   Over SSH (what .github/workflows/supabase-migrations.yml does):
#     PSQL="ssh vps docker exec -i supabase-db psql -U postgres -d postgres" supabase/apply_migrations.sh
#
# DRY_RUN=1 lists the pending migrations without applying them.
set -euo pipefail

: "${PSQL:?Set PSQL to the command that runs psql on the server}"
DRY_RUN="${DRY_RUN:-0}"
dir="$(cd "$(dirname "$0")" && pwd)/migrations"

run_sql() { $PSQL -v ON_ERROR_STOP=1 -q "$@"; }

run_sql <<'SQL'
set client_min_messages = warning;
create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version    text primary key,
  statements text[],
  name       text
);
SQL

applied="$(echo 'select version from supabase_migrations.schema_migrations;' | run_sql -tA)"

pending=0
for file in "$dir"/*.sql; do
  base="$(basename "$file" .sql)"
  version="${base%%_*}"
  name="${base#*_}"
  if grep -qx "$version" <<<"$applied"; then
    continue
  fi
  pending=$((pending + 1))
  if [ "$DRY_RUN" = "1" ]; then
    echo "pending: $base"
    continue
  fi
  echo "applying: $base"
  # One transaction per file: the migration and its bookkeeping row land
  # together or not at all.
  {
    echo 'set client_min_messages = warning;'
    echo 'begin;'
    cat "$file"
    echo
    echo "insert into supabase_migrations.schema_migrations (version, name) values ('$version', '$name');"
    echo 'commit;'
  } | run_sql
done

if [ "$pending" -eq 0 ]; then
  echo "Server is up to date."
fi
