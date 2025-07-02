.PHONY: up down build clean logs ps generate-config

# Generate configuration files
generate-config:
	@chmod +x scripts/generate-config.sh
	@./scripts/generate-config.sh

# Start all services
up: generate-config
	docker compose up -d

# Start with build
build: generate-config
	docker compose up --build -d

# Stop all services
down:
	docker compose down

# View logs
logs:
	docker compose logs -f

# Show running containers
ps:
	docker compose ps

# Clean everything (WARNING: Deletes data)
clean:
	docker compose down -v
	docker system prune -f

# Production deployment
prod-deploy: generate-config
	docker compose -f docker-compose.yml up -d --build

# Test connections
test:
	@echo "Testing database connections..."
	@psql -h localhost -p $${POSTGRES_PORT} -U $${POSTGRES_USER} -d $${POSTGRES_DB} -c "SELECT version();"
	@psql -h localhost -p $${PGBOUNCER_PORT} -U $${POSTGRES_USER} -d $${POSTGRES_DB} -c "SELECT 1;" 