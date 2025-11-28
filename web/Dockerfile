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
