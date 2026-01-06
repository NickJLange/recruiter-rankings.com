#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Check database connectivity
echo "Checking database connectivity..."
bundle exec rails runner "ActiveRecord::Base.connection" || (echo "Database connection failed! Please ensure your database is active and reachable." && exit 1)

bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate
