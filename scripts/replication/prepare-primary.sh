#!/bin/bash
set -euo pipefail

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

COMPOSE_CMD=${COMPOSE_CMD:-docker compose}
PRIMARY_SERVICE=${PRIMARY_SERVICE:-db}
REPL_USER=${POSTGRES_REPLICATION_USER:-replicator}
REPL_PASSWORD=${POSTGRES_REPLICATION_PASSWORD:-replicator_password}
REPL_SLOT=${POSTGRES_REPLICATION_SLOT:-replica_slot_1}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
PG_HBA_ENTRY="host replication ${REPL_USER} 0.0.0.0/0 md5"

run_psql() {
  if [ -z "$POSTGRES_PASSWORD" ]; then
    ${COMPOSE_CMD} exec -T "$PRIMARY_SERVICE" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$1"
  else
    ${COMPOSE_CMD} exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$PRIMARY_SERVICE" \
      psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$1"
  fi
}

echo "[prepare-primary] creating replication role if needed"
run_psql "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${REPL_USER}') THEN EXECUTE format('CREATE ROLE %I WITH REPLICATION LOGIN PASSWORD %L', '${REPL_USER}', '${REPL_PASSWORD}'); END IF; END $$;"

echo "[prepare-primary] creating replication slot ${REPL_SLOT} if needed"
run_psql "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = '${REPL_SLOT}') THEN PERFORM pg_create_physical_replication_slot('${REPL_SLOT}'); END IF; END $$;"

echo "[prepare-primary] applying replication configuration via ALTER SYSTEM"
run_psql "ALTER SYSTEM SET wal_level = 'replica';"
run_psql "ALTER SYSTEM SET max_wal_senders = '10';"
run_psql "ALTER SYSTEM SET max_replication_slots = '10';"
run_psql "ALTER SYSTEM SET wal_keep_size = '512MB';"

PG_HBA_CMD="HBA=/var/lib/postgresql/data/pg_hba.conf; if ! grep -q \"${PG_HBA_ENTRY}\" \"$HBA\"; then echo \"${PG_HBA_ENTRY}\" >> \"$HBA\"; fi"
echo "[prepare-primary] ensuring pg_hba.conf allows replication"
if [ -z "$POSTGRES_PASSWORD" ]; then
  ${COMPOSE_CMD} exec -T "$PRIMARY_SERVICE" bash -lc "$PG_HBA_CMD"
else
  ${COMPOSE_CMD} exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" "$PRIMARY_SERVICE" bash -lc "$PG_HBA_CMD"
fi

echo "[prepare-primary] done. Please restart the primary service (docker compose restart ${PRIMARY_SERVICE}) for wal_level changes to take effect."
