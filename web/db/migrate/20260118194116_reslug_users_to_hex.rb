class ReslugUsersToHex < ActiveRecord::Migration[8.1]
  def up
    # Use raw SQL to avoid loading the User model class, which would trigger
    # enum definitions that may reference columns not yet added by later migrations.
    rows = execute("SELECT id, public_slug FROM users").to_a
    rows.each do |row|
      id   = row["id"]
      slug = row["public_slug"]

      # Skip if already 8-char uppercase hex
      next if slug&.match?(/\A[0-9A-F]{8}\z/)

      new_slug = nil
      loop do
        candidate = SecureRandom.hex(4).upcase
        existing = execute("SELECT 1 FROM users WHERE public_slug = #{connection.quote(candidate)} LIMIT 1").to_a
        next if existing.any?
        new_slug = candidate
        break
      end

      execute("UPDATE users SET public_slug = #{connection.quote(new_slug)} WHERE id = #{id}")
    end
  end
end
