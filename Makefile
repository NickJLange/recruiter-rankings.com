SHELL := /bin/bash

# Use podman-compose if available, otherwise fall back to podman commands
PODMAN := podman
COMPOSE_FILE := podman-compose.yml

.PHONY: help db-up db-down db-logs db-psql db-reset db-nuke db-status web-setup web-server web-test

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

# Database management
db-up: ## Start PostgreSQL container
	@echo "Starting PostgreSQL container with Podman..."
	@$(PODMAN) play kube $(COMPOSE_FILE) 2>/dev/null || \
		$(PODMAN) run -d \
		--name rr-postgres \
		-e POSTGRES_USER=postgres \
		-e POSTGRES_PASSWORD=postgres \
		-e POSTGRES_DB=postgres \
		-p 5432:5432 \
		-v rr-postgres-data:/var/lib/postgresql/data \
		--health-cmd="pg_isready -U postgres" \
		--health-interval=5s \
		--health-timeout=3s \
		--health-retries=5 \
		docker.io/library/postgres:16
	@echo "Waiting for database to be ready..."
	@sleep 3
	@$(PODMAN) ps --filter name=rr-postgres

db-down: ## Stop PostgreSQL container
	@echo "Stopping PostgreSQL container..."
	@$(PODMAN) stop rr-postgres 2>/dev/null || true
	@$(PODMAN) rm rr-postgres 2>/dev/null || true

db-logs: ## Show PostgreSQL container logs
	@$(PODMAN) logs -f rr-postgres

db-status: ## Show PostgreSQL container status
	@$(PODMAN) ps --filter name=rr-postgres

db-psql: ## Connect to PostgreSQL with psql
	@$(PODMAN) exec -it rr-postgres psql -U postgres -d postgres

db-reset: db-up ## Reset database (drop, create, migrate, seed)
	@echo "Resetting database..."
	@cd web && bundle install
	@cd web && bin/rails db:drop db:create db:migrate db:seed
	@echo "Database reset complete!"

db-nuke: ## Completely remove container and volume
	@echo "Removing PostgreSQL container and volume..."
	@$(PODMAN) stop rr-postgres 2>/dev/null || true
	@$(PODMAN) rm rr-postgres 2>/dev/null || true
	@$(PODMAN) volume rm rr-postgres-data 2>/dev/null || true
	@echo "Container and volume removed!"

# Rails application
web-setup: db-up ## Setup Rails app with database
	@echo "Setting up Rails application..."
	@cd web && bundle install
	@cd web && bin/rails db:prepare
	@cd web && bin/rails db:seed
	@echo "Rails application setup complete!"

web-server: ## Start Rails development server
	@cd web && bin/dev

web-test: ## Run Rails test suite
	@cd web && bin/rails test

# Full stack operations
dev: db-up ## Start database and Rails server
	@echo "Starting full development stack..."
	@$(MAKE) web-server

setup: ## Initial project setup
	@echo "Setting up project..."
	@$(MAKE) web-setup
	@echo "Project setup complete! Run 'make dev' to start the server."