# Streaming Replica Add-On

This directory keeps optional tooling for adding a hot-standby replica without changing the original `docker-compose.yml` stack. The idea is:

1. Prepare the existing primary container (`db`) so it allows replication.
2. Start an additional container that performs `pg_basebackup` from the primary and stays in continuous recovery.

## 1. Prepare the Primary

> **Important:** Enabling `wal_level = replica` requires a restart of the primary database container. Plan a short maintenance window.

Anda dapat menyalin `replication/.env.replica.example` menjadi `replication/.env.replica`, lalu sesuaikan user/slot/password bila diperlukan. Setiap variabel di file itu bisa diexport sebelum menjalankan perintah berikut.

```bash
# from the repository root
# optional: load replica overrides
set -a; [ -f replication/.env.replica ] && . replication/.env.replica; set +a

./scripts/replication/prepare-primary.sh

# restart to apply wal_level change
docker compose restart db
```

The script will:
- create a replication role (defaults: user `replicator`, password `replicator_password`)
- create a physical replication slot (`replica_slot_1`)
- set `wal_level`, `max_wal_senders`, `max_replication_slots`, `wal_keep_size`
- append a replication entry to `pg_hba.conf`

Set environment variables before running if you want different credentials:

```bash
POSTGRES_REPLICATION_USER=myrepl \
POSTGRES_REPLICATION_PASSWORD=secret \
POSTGRES_REPLICATION_SLOT=myreplica \
  ./scripts/replication/prepare-primary.sh
```

## 2. Launch the Replica Container

The replica runs from a small Compose override file so the original stack stays untouched.

```bash
# first create replica data directory (separate from primary volume)
mkdir -p data_timescale_replica
sudo chown 999:999 data_timescale_replica
sudo chmod 700 data_timescale_replica

# start replica alongside the existing project
set -a; [ -f replication/.env.replica ] && . replication/.env.replica; set +a
docker compose \
  -f docker-compose.yml \
  -f replication/docker-compose.replica.yml \
  up -d db_replica
```

By default it connects to the primary service `db` on port `5432`. You can override host/port and replication credentials on the fly:

```bash
POSTGRES_REPLICATION_USER=myrepl \
POSTGRES_REPLICATION_PASSWORD=secret \
POSTGRES_REPLICATION_SLOT=myreplica \
PRIMARY_HOST=db \
PRIMARY_PORT=5432 \
DB_REPLICA_DATA_PATH=./data_timescale_replica \
DB_REPLICA_PORT=5440 \
  docker compose -f docker-compose.yml -f replication/docker-compose.replica.yml up -d db_replica
```

The entrypoint script waits for the primary, runs `pg_basebackup` into `data_timescale_replica`, and starts PostgreSQL in standby mode. If `DB_REPLICA_PORT` is not set, Docker maps the replica to a random free local port (check with `docker compose port db_replica 5432`).

## 3. Validate Replication

```bash
# On the primary
docker compose exec db \
  psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} \
  -c "SELECT application_name, state, sync_state, write_lag, flush_lag FROM pg_stat_replication;"

# On the replica
docker compose exec db_replica \
  psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} \
  -c "SELECT pg_is_in_recovery();"
```

`pg_is_in_recovery()` should return `t`. On the primary you should see your replica listed with `state = 'streaming'`.

## Cleanup

Stop the replica with:

```bash
docker compose -f docker-compose.yml -f replication/docker-compose.replica.yml down db_replica
```

Remove the replica data directory (`data_timescale_replica`) only if you are sure you no longer need it.

---

Feel free to adapt these scripts (e.g. add monitoring user, tweak slots). They intentionally stay separate from the main stack to keep the production container untouched.
