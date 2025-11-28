# Recruiter Rankings

A Rails 8.1 application for ranking and reviewing recruiters.

## Prerequisites

- Ruby 3.4.7 (managed via rbenv)
- PostgreSQL
- Bundler 2.7.1

## Local Development Setup

### 1. Install Ruby with rbenv

```bash
# Install rbenv if not already installed (macOS)
brew install rbenv ruby-build

# Add rbenv to your shell (add to ~/.zshrc or ~/.bashrc)
eval "$(rbenv init - zsh)"

# Install Ruby 3.4.7
rbenv install 3.4.7
```

### 2. Clone and Setup

```bash
git clone <repository-url>
cd web

# Verify Ruby version is set (should show 3.4.7)
cat .ruby-version

# Install bundler
gem install bundler -v 2.7.1

# Install dependencies
bundle install
```

### 3. Database Setup

```bash
# Create and setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # Optional: seed with sample data
```

### 4. Environment Configuration

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your local settings
# For development, defaults should work
```

### 5. Run the Application

```bash
# Verify your setup (optional)
bin/setup-check

# Start Rails server
bin/rails server

# Visit http://localhost:3000
```

## Docker Setup

### Dockerfile

Create a `Dockerfile` in the project root:

```dockerfile
FROM ruby:3.4.7-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    tzdata

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Copy application code
COPY . .

# Precompile assets
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
```

### docker-compose.yml

Create a `docker-compose.yml` for local development:

```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: web_development
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  web:
    build: .
    command: bin/rails server -b 0.0.0.0
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgres://postgres:postgres@db:5432/web_development
      RAILS_ENV: development
    depends_on:
      - db

volumes:
  postgres_data:
```

### Running with Docker

```bash
# Build and start containers
docker-compose up --build

# Run migrations (in another terminal)
docker-compose exec web bin/rails db:create db:migrate

# Stop containers
docker-compose down
```

## Deployment to Render.com

### Method 1: Render Dashboard (Recommended for beginners)

1. **Create a Web Service**
   - Go to [render.com](https://render.com) and sign in
   - Click "New +" → "Web Service"
   - Connect your GitHub/GitLab repository

2. **Configure Service**
   - **Name**: `recruiter-rankings`
   - **Environment**: `Ruby`
   - **Build Command**: `bundle install; bundle exec rails assets:precompile`
   - **Start Command**: `bundle exec rails server -b 0.0.0.0 -p $PORT`
   - **Instance Type**: Choose based on your needs (Free or Starter)

3. **Add PostgreSQL Database**
   - Click "New +" → "PostgreSQL"
   - Create database and link it to your web service
   - Render will automatically set `DATABASE_URL`

4. **Environment Variables**
   Set these in the Render Dashboard under "Environment":
   ```
   RAILS_ENV=production
   SECRET_KEY_BASE=<generate with `rails secret`>
   RAILS_LOG_LEVEL=info
   RAILS_MAX_THREADS=5
   WEB_CONCURRENCY=2
   ```

   Optional variables (see `.env.example` for full list):
   ```
   CANONICAL_URL=https://your-app.onrender.com
   PUBLIC_MIN_REVIEWS=5
   SUBMISSION_EMAIL_HMAC_PEPPER=<generate random string>
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Render will automatically deploy on every push to your main branch

### Method 2: render.yaml (Infrastructure as Code)

Create a `render.yaml` in your repository root:

```yaml
services:
  - type: web
    name: recruiter-rankings
    env: ruby
    buildCommand: bundle install; bundle exec rails assets:precompile
    startCommand: bundle exec rails server -b 0.0.0.0 -p $PORT
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_LOG_LEVEL
        value: info
      - key: RAILS_MAX_THREADS
        value: 5
      - key: WEB_CONCURRENCY
        value: 2
      - key: SECRET_KEY_BASE
        generateValue: true
      - key: DATABASE_URL
        fromDatabase:
          name: recruiter-rankings-db
          property: connectionString

databases:
  - name: recruiter-rankings-db
    databaseName: recruiter_rankings
    plan: free  # or 'starter' for production
```

Commit this file and Render will detect it automatically.

### Running Migrations on Render

```bash
# Via Render Dashboard Shell
# Go to your service → "Shell" tab
bundle exec rails db:migrate

# Or via Render CLI (if installed)
render exec bundle exec rails db:migrate
```

### Render-Specific Notes

- **Ruby Version**: Render will use the version specified in `.ruby-version`
- **Bundler Version**: Specified in `Gemfile.lock` (BUNDLED WITH section)
- **Automatic Deploys**: Enabled by default for your main branch
- **Free Tier**: Services spin down after 15 minutes of inactivity
- **Health Checks**: Render automatically monitors `/` endpoint

## Testing

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/recruiter_test.rb

# Run security scan
bundle exec brakeman
```

## Common Issues

### "cannot load bundler" error
- Ensure rbenv is initialized: `eval "$(rbenv init - zsh)"`
- Add to `~/.zshrc` to make permanent
- Install correct bundler version: `gem install bundler -v 2.7.1`

### Database connection errors
- Verify PostgreSQL is running: `brew services list` (macOS)
- Check DATABASE_URL in `.env`

### Asset compilation fails on Render
- Ensure `SECRET_KEY_BASE` is set in environment variables
- Check build logs for missing dependencies

## Development Tools

- **Code Quality**: `bundle exec brakeman` (security scanner)
- **Linting**: Configure rubocop if needed
- **Debugging**: Use the `debug` gem (already in Gemfile)
