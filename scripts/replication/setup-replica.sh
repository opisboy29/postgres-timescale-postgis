#!/bin/bash
set -euo pipefail

DATA_DIR=${PGDATA:-/var/lib/postgresql/data}
PRIMARY_HOST=${PRIMARY_HOST:-db}
PRIMARY_PORT=${PRIMARY_PORT:-5432}
REPL_USER=${POSTGRES_REPLICATION_USER:-replicator}
REPL_PASSWORD=${POSTGRES_REPLICATION_PASSWORD:-replicator_password}
REPL_SLOT=${POSTGRES_REPLICATION_SLOT:-replica_slot_1}
APP_NAME=${POSTGRES_REPLICA_APPLICATION_NAME:-replica_1}
PRIMARY_READY_USER=${PRIMARY_READY_USER:-${REPL_USER:-${POSTGRES_USER:-postgres}}}

wait_for_primary() {
  echo "[replica] waiting for primary ${PRIMARY_HOST}:${PRIMARY_PORT}"
  export PGPASSWORD="${REPL_PASSWORD}"
  until pg_isready -h "${PRIMARY_HOST}" -p "${PRIMARY_PORT}" -U "${PRIMARY_READY_USER}" >/dev/null 2>&1; do
    sleep 2
  done
  unset PGPASSWORD
}

bootstrap_replica() {
  echo "[replica] bootstrapping data directory"
  rm -rf "${DATA_DIR}"/*
  export PGPASSWORD="${REPL_PASSWORD}"
  pg_basebackup \
    -h "${PRIMARY_HOST}" \
    -p "${PRIMARY_PORT}" \
    -D "${DATA_DIR}" \
    -U "${REPL_USER}" \
    -P \
    -X stream \
    -R \
    --slot="${REPL_SLOT}"

  cat <<CONF > "${DATA_DIR}/postgresql.auto.conf"
primary_conninfo = 'host=${PRIMARY_HOST} port=${PRIMARY_PORT} user=${REPL_USER} password=${REPL_PASSWORD} application_name=${APP_NAME}'
primary_slot_name = '${REPL_SLOT}'
CONF

  touch "${DATA_DIR}/standby.signal"
  chown -R postgres:postgres "${DATA_DIR}"
  chmod 700 "${DATA_DIR}"
  unset PGPASSWORD
}

if [ ! -f "${DATA_DIR}/PG_VERSION" ]; then
  wait_for_primary
  bootstrap_replica
else
  echo "[replica] existing data directory detected, skipping bootstrap"
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
