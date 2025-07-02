# PostgreSQL with TimescaleDB & PostGIS

A production-ready PostgreSQL setup with TimescaleDB (time-series) and PostGIS (geospatial) extensions, complete with PgBouncer connection pooling and Prometheus monitoring.

## 🚀 Features

- **PostgreSQL 15** - Latest stable version
- **TimescaleDB 2.20.3** - Time-series database extension
- **PostGIS 3.5.3** - Geospatial database extension
- **PgBouncer** - Connection pooling (2000 max connections)
- **Prometheus Exporter** - Monitoring and metrics
- **Production-optimized** - Performance-tuned configuration
- **Multi-database support** - 6 pre-configured databases
- **Environment-based config** - Secure credential management

## 📋 Prerequisites

- Docker & Docker Compose
- `psql` client (for testing)
- `make` (optional, for convenience commands)
- `envsubst` (for config generation)

## 🛠 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd postgres-timescale-postgis
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env
```

### 3. Deploy

```bash
# Generate configs and start services
make build

# Or manually:
# chmod +x scripts/generate-config.sh
# ./scripts/generate-config.sh
# docker-compose up --build -d
```

### 4. Verify Setup

```bash
# Test connections
make test

# Check logs
make logs

# View container status
make ps
```

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | Database username | `postgres` |
| `POSTGRES_PASSWORD` | Database password | *required* |
| `POSTGRES_DB` | Default database | `timescaledb` |
| `POSTGRES_PORT` | External PostgreSQL port | `5431` |
| `PGBOUNCER_PORT` | External PgBouncer port | `6431` |
| `POSTGRES_EXPORTER_PORT` | Metrics port | `9188` |
| `DB_MAX_CONNECTIONS` | Max database connections | `1500` |
| `PGBOUNCER_MAX_CLIENT_CONN` | Max client connections | `2000` |

### Databases Created

The setup automatically creates 6 databases with all extensions:

1. **timescaledb** - Main database
2. **postgres** - Default PostgreSQL database  
3. **k3i_public** - Application database
4. **logger** - Logging database
5. **k3i2023_stagging** - Staging environment
6. **k3i2022_v3** - Legacy version

### Extensions Installed

Each database includes:
- `timescaledb` - Time-series functionality
- `postgis` - Geospatial functionality
- `postgis_topology` - Topology support
- `postgis_raster` - Raster data support
- `plpgsql` - Procedural language

## 🔌 Connection Examples

### Direct PostgreSQL Connection

```bash
# Connect directly to PostgreSQL
psql -h localhost -p 5431 -U postgres -d timescaledb

# Connect to specific database
psql -h localhost -p 5431 -U postgres -d k3i_public
```

### PgBouncer Connection (Recommended)

```bash
# Connect via PgBouncer (connection pooling)
psql -h localhost -p 6431 -U postgres -d timescaledb

# Application connection string
postgresql://postgres:your_password@localhost:6431/timescaledb
```

## 📊 Usage Examples

### TimescaleDB (Time-Series)

```sql
-- Create a hypertable for sensor data
CREATE TABLE sensor_data (
    time TIMESTAMPTZ NOT NULL,
    sensor_id TEXT,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);

-- Convert to hypertable (TimescaleDB)
SELECT create_hypertable('sensor_data', 'time');

-- Insert time-series data
INSERT INTO sensor_data VALUES 
    (NOW(), 'sensor_001', 25.5, 65.2),
    (NOW() - INTERVAL '1 hour', 'sensor_001', 24.8, 67.1);

-- Query recent data
SELECT * FROM sensor_data 
WHERE time > NOW() - INTERVAL '24 hours'
ORDER BY time DESC;
```

### PostGIS (Geospatial)

```sql
-- Create table with geometry
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name TEXT,
    location GEOMETRY(POINT, 4326)
);

-- Insert geospatial data
INSERT INTO locations VALUES 
    (1, 'Jakarta', ST_GeomFromText('POINT(106.8456 -6.2088)', 4326)),
    (2, 'Bandung', ST_GeomFromText('POINT(107.6098 -6.9175)', 4326));

-- Spatial query (distance calculation)
SELECT 
    name,
    ST_Distance_Sphere(location, ST_GeomFromText('POINT(106.8456 -6.2088)', 4326))/1000 as distance_km
FROM locations
ORDER BY distance_km;
```

### Combined TimescaleDB + PostGIS

```sql
-- Create table with both time-series and geospatial data
CREATE TABLE sensor_readings (
    time TIMESTAMPTZ NOT NULL,
    sensor_id TEXT,
    temperature DOUBLE PRECISION,
    location GEOMETRY(POINT, 4326)
);

-- Convert to hypertable
SELECT create_hypertable('sensor_readings', 'time');

-- Insert data
INSERT INTO sensor_readings VALUES 
    (NOW(), 'jakarta_001', 28.5, ST_GeomFromText('POINT(106.8456 -6.2088)', 4326)),
    (NOW(), 'bandung_001', 23.1, ST_GeomFromText('POINT(107.6098 -6.9175)', 4326));

-- Query with both time and spatial filters
SELECT 
    sensor_id,
    temperature,
    ST_AsText(location) as coordinates,
    time
FROM sensor_readings 
WHERE time > NOW() - INTERVAL '1 hour'
  AND ST_DWithin(location, ST_GeomFromText('POINT(106.8456 -6.2088)', 4326), 0.1)
ORDER BY time DESC;
```

## 📈 Monitoring

### Prometheus Metrics

Access metrics at: `http://localhost:9188/metrics`

```bash
# Check basic metrics
curl http://localhost:9188/metrics | grep pg_up

# Database statistics
curl http://localhost:9188/metrics | grep pg_stat_database
```

### PgBouncer Statistics

```sql
-- Connect to PgBouncer admin
psql -h localhost -p 6431 -U postgres -d pgbouncer

-- View connection pools
SHOW POOLS;

-- View database connections
SHOW DATABASES;

-- View statistics
SHOW STATS;
```

## 🔧 Management Commands

### Using Makefile

```bash
# Start services
make up

# Build and start
make build

# Stop services
make down

# View logs
make logs

# Show container status
make ps

# Generate configuration files
make generate-config

# Clean everything (WARNING: Deletes data)
make clean

# Production deployment
make prod-deploy

# Test connections
make test
```

### Manual Docker Compose

```bash
# Start services
docker-compose up -d

# Build and start
docker-compose up --build -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f db

# Scale services
docker-compose up -d --scale pgbouncer=2
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Permission Denied on Data Directory

```bash
# Fix data directory permissions
sudo chown -R 999:999 ./data_timescale
```

#### 2. Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :5431

# Change port in .env file
POSTGRES_PORT=5433
```

#### 3. Connection Refused

```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs db

# Restart services
docker-compose restart
```

#### 4. Extension Not Found

```bash
# Rebuild with fresh data
docker-compose down -v
docker-compose up --build -d
```

### Database Recovery

```bash
# Backup database
pg_dump -h localhost -p 5431 -U postgres -d timescaledb > backup.sql

# Restore database
psql -h localhost -p 5431 -U postgres -d timescaledb < backup.sql
```

## 🔐 Security Best Practices

### For Production

1. **Change Default Credentials**
   ```bash
   # Generate strong password
   openssl rand -base64 32
   ```

2. **Use Environment Files**
   ```bash
   # Don't commit .env to git
   echo ".env" >> .gitignore
   ```

3. **Network Security**
   ```yaml
   # Add to docker-compose.yml
   networks:
     postgres_network:
       driver: bridge
   ```

4. **Enable SSL**
   ```bash
   # Generate SSL certificates
   openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key
   ```

## 📦 Production Deployment

### 1. Server Setup

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Deploy Application

```bash
# Clone repository
git clone <your-repo>
cd postgres-timescale-postgis

# Setup environment
cp .env.example .env
nano .env  # Configure production settings

# Deploy
make prod-deploy

# Verify
make test
```

### 3. Backup Strategy

```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec -T db pg_dump -U postgres timescaledb > backup_${DATE}.sql
gzip backup_${DATE}.sql
EOF

chmod +x backup.sh

# Add to crontab for daily backups
0 2 * * * /path/to/backup.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Documentation**: [TimescaleDB Docs](https://docs.timescale.com/)
- **PostGIS**: [PostGIS Documentation](https://postgis.net/documentation/)

## 🙏 Acknowledgments

- [TimescaleDB](https://www.timescale.com/) - Time-series database
- [PostGIS](https://postgis.net/) - Spatial database extension
- [PgBouncer](https://www.pgbouncer.org/) - Connection pooler
- [PostgreSQL](https://www.postgresql.org/) - The world's most advanced open source database

---

**Made with ❤️ for the community** 