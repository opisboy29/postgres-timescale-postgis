# Use official PostgreSQL image with Debian
FROM postgres:15

# Install TimescaleDB repository and PostGIS
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add TimescaleDB repository (FIXED)
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/timescaledb.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/timescaledb.gpg] https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | \
    tee /etc/apt/sources.list.d/timescaledb.list

# Install TimescaleDB and PostGIS
RUN apt-get update && apt-get install -y \
    timescaledb-2-postgresql-15 \
    postgresql-15-postgis-3 \
    postgresql-15-postgis-3-scripts \
    && rm -rf /var/lib/apt/lists/*

# Configure PostgreSQL to load TimescaleDB
RUN echo "shared_preload_libraries = 'timescaledb'" >> /usr/share/postgresql/postgresql.conf.sample

# Enable TimescaleDB in the container upon startup
CMD ["postgres", "-c", "shared_preload_libraries=timescaledb"]
