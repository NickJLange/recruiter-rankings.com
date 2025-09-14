SHELL := /bin/bash

.PHONY: help db-up db-down db-logs db-psql db-reset db-nuke db-status web-setup web-server web-test

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

# Database management
db-up: ## Start PostgreSQL container
	@echo "Starting PostgreSQL container..."
	@docker compose up -d db
	@echo "Waiting for database to be ready..."
	@sleep 3
	@docker compose ps

db-down: ## Stop PostgreSQL container
	@echo "Stopping PostgreSQL container..."
	@docker compose down

db-logs: ## Show PostgreSQL container logs
	@docker compose logs -f db

db-status: ## Show PostgreSQL container status
	@docker compose ps

db-psql: ## Connect to PostgreSQL with psql
	@docker compose exec -it db psql -U postgres -d postgres

db-reset: db-up ## Reset database (drop, create, migrate, seed)
	@echo "Resetting database..."
	@cd web && bundle install
	@cd web && bin/rails db:drop db:create db:migrate db:seed
	@echo "Database reset complete!"

db-nuke: ## Completely remove container and volume
	@echo "Removing PostgreSQL container and volume..."
	@docker compose down -v
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