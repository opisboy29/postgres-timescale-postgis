-- Enable TimescaleDB extension in current database (timescaledb)
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Create additional databases for pgbouncer.ini
-- Using simple CREATE (will show error if exists but that's OK)
CREATE DATABASE k3i_public;
CREATE DATABASE logger;
CREATE DATABASE k3i2023_stagging;
CREATE DATABASE k3i2022_v3;

-- Add extensions to postgres database (default database)
\c postgres;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Add extensions to k3i_public database
\c k3i_public;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Add extensions to logger database
\c logger;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Add extensions to k3i2023_stagging database
\c k3i2023_stagging;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Add extensions to k3i2022_v3 database
\c k3i2022_v3;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Back to timescaledb database and show summary
\c timescaledb;

-- Show all databases
\l

-- Show extensions in current database
SELECT 
    current_database() as database_name,
    extname as extension_name,
    extversion as version
FROM pg_extension 
WHERE extname IN ('timescaledb', 'postgis', 'postgis_topology', 'postgis_raster', 'plpgsql')
ORDER BY extname;

-- Summary message
\echo 'Setup completed! All databases created with extensions:'
\echo '- postgres'
\echo '- timescaledb'
\echo '- k3i_public'
\echo '- logger'
\echo '- k3i2023_stagging'
\echo '- k3i2022_v3' 