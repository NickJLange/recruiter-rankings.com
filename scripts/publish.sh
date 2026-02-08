#!/bin/bash
set -e

# Configuration
ALLOWED_LOCALES=("ja" "es" "fr" "ar")

echo "==> Publishing process started..."

# 1. Ensure we are on main
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Error: Must be on main branch to publish."
  exit 1
fi

# 2. Pull latest locales from language branches
for lang in "${ALLOWED_LOCALES[@]}"; do
  echo "--> Fetching locale: $lang from branch lang-$lang"
  # Pull specific file from branch without switching
  git show "lang-$lang:web/config/locales/$lang.yml" > "web/config/locales/$lang.yml" 2>/dev/null || echo "Warning: web/config/locales/$lang.yml not found on branch lang-$lang"
  git show "lang-$lang:site/_data/i18n/$lang.yml" > "site/_data/i18n/$lang.yml" 2>/dev/null || echo "Warning: site/_data/i18n/$lang.yml not found on branch lang-$lang"
done

# 3. Verify all locales are present
echo "--> Verifying translation coverage..."
(cd web && bundle exec rake i18n:audit)

echo "==> Ready for build/deployment."
