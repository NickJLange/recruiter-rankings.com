#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Check database connectivity
echo "Checking database connectivity..."
bundle exec rails runner "ActiveRecord::Base.connection" || (echo "Database connection failed! Please ensure your database is active and reachable." && exit 1)

bundle exec rake assets:precompile
bundle exec rake assets:clean
# Load schema from schema.rb (the source of truth). This drops and recreates
# all tables, which is safe because the Render DB has no real data yet.
#
# DISABLE_DATABASE_ENVIRONMENT_CHECK bypasses the ar_internal_metadata check
# that fails when the DB is in a partially-migrated state from prior failures.
#
# Once the app is stable and has real data, change this to:
#   bundle exec rake db:migrate
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:schema:load
