#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Check database connectivity
echo "Checking database connectivity..."
bundle exec rails runner "ActiveRecord::Base.connection" || (echo "Database connection failed! Please ensure your database is active and reachable." && exit 1)

bundle exec rake assets:precompile
bundle exec rake assets:clean
# On a fresh database (no schema_migrations rows), load schema directly to avoid
# migration ordering issues. On an existing database, run incremental migrations.
bundle exec rails runner "
  begin
    count = ActiveRecord::Base.connection.execute('SELECT COUNT(*) FROM schema_migrations').first['count'].to_i
    if count == 0
      puts 'Fresh database detected — loading schema directly'
      system('bundle exec rake db:schema:load') || exit(1)
    else
      puts \"Existing database (#{count} migrations applied) — running db:migrate\"
      system('bundle exec rake db:migrate') || exit(1)
    end
  rescue => e
    puts \"Schema check failed: #{e.message} — loading schema directly\"
    system('bundle exec rake db:schema:load') || exit(1)
  end
"
