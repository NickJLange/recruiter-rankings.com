# Database Setup for Recruiter Rankings

This project supports two database setup options for local development:

## Option 1: Dockerized PostgreSQL (Recommended)

### Prerequisites
- Docker Desktop for Mac: https://www.docker.com/products/docker-desktop/
- Make sure Docker is running before proceeding

### Quick Start
```bash
# Start the database container
make db-up

# Initial setup (creates databases, runs migrations, seeds data)
make setup

# Start the Rails server
make dev
```

### Common Commands
```bash
make help         # Show all available commands
make db-up        # Start PostgreSQL container
make db-down      # Stop PostgreSQL container
make db-status    # Check container status
make db-logs      # View PostgreSQL logs
make db-psql      # Connect to PostgreSQL CLI
make db-reset     # Reset database (drop/create/migrate/seed)
make db-nuke      # Completely remove container and data
make web-test     # Run Rails test suite
```

### Configuration
The Docker setup uses these defaults (configured in `docker-compose.yml` and `web/.env`):
- PostgreSQL version: 16
- Database user: postgres
- Database password: postgres
- Development database: rr_dev
- Test database: rr_test
- Port: 5432

## Option 2: Local PostgreSQL Installation

If you prefer to use a locally installed PostgreSQL:

### Prerequisites
Install PostgreSQL using Homebrew:
```bash
brew install postgresql@16
brew services start postgresql@16
```

### Configuration
1. Update `web/.env` with your local PostgreSQL settings:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=your_username
DB_PASSWORD=your_password
DB_NAME=rr_dev
DB_NAME_TEST=rr_test
```

2. Create the databases:
```bash
cd web
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

3. Start the Rails server:
```bash
cd web
bin/dev
```

## Environment Variables

Both setups use environment variables configured in `web/.env` (not committed to git).
See `web/.env.example` for all available configuration options.

Key database environment variables:
- `DB_HOST`: Database host (default: 127.0.0.1)
- `DB_PORT`: Database port (default: 5432)
- `DB_USER`: Database username (default: postgres)
- `DB_PASSWORD`: Database password (default: postgres)
- `DB_NAME`: Development database name (default: rr_dev)
- `DB_NAME_TEST`: Test database name (default: rr_test)

## Production

Production deployment on Render.com uses a managed PostgreSQL instance.
The production configuration in `web/config/database.yml` uses the `DATABASE_URL`
environment variable provided by Render. No changes to production settings are needed.

## Troubleshooting

### Port Already in Use
If port 5432 is already in use:
1. Update `docker-compose.yml` to use a different port mapping (e.g., `"5433:5432"`)
2. Update `DB_PORT=5433` in `web/.env`
3. Update the `DATABASE_URL` in `web/.env` to use the new port

### Database Connection Issues
- Ensure Docker Desktop is running (Option 1) or PostgreSQL service is running (Option 2)
- Check that environment variables in `web/.env` match your setup
- Run `docker compose ps` to verify the container is healthy (Option 1)
- Try connecting directly: `psql postgresql://postgres:postgres@127.0.0.1:5432/postgres`

### Reset Everything (Docker)
```bash
make db-nuke  # Remove container and volumes
make setup    # Fresh setup
```

### Reset Everything (Local PostgreSQL)
```bash
cd web
bin/rails db:drop
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```