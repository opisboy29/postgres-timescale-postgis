.PHONY: up down build clean logs ps generate-config projects

# Load environment variables
include .env
export

# Generate configuration files
generate-config:
	@chmod +x scripts/generate-config.sh
	@./scripts/generate-config.sh

# Start all services
up: generate-config
	docker compose -p $(PROJECT_NAME) up -d

# Start with build
build: generate-config
	docker compose -p $(PROJECT_NAME) up --build -d

# Stop all services
down:
	docker compose -p $(PROJECT_NAME) down

# View logs
logs:
	docker compose -p $(PROJECT_NAME) logs -f

# Show running containers
ps:
	docker compose -p $(PROJECT_NAME) ps

# Clean everything (WARNING: Deletes data)
clean:
	docker compose -p $(PROJECT_NAME) down -v
	docker system prune -f

# Production deployment
prod-deploy: generate-config
	docker compose -p $(PROJECT_NAME) up -d --build

# Test connections
test:
	@echo "Testing database connections for project: $(PROJECT_NAME)"
	@echo "PostgreSQL: localhost:$(POSTGRES_PORT)"
	@echo "PgBouncer: localhost:$(PGBOUNCER_PORT)"
	@echo "Metrics: localhost:$(POSTGRES_EXPORTER_PORT)"
	@psql -h localhost -p $(POSTGRES_PORT) -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "SELECT version();" || echo "Direct connection failed"
	@psql -h localhost -p $(PGBOUNCER_PORT) -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "SELECT 1;" || echo "PgBouncer connection failed"

# Show all projects
projects:
	@echo "All Docker Compose projects:"
	@docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | grep -E "(postgres|pgbouncer|exporter)" 