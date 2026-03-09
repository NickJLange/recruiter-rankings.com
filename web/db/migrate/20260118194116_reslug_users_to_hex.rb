class ReslugUsersToHex < ActiveRecord::Migration[8.1]
  def up
    User.find_each do |user|
      # Skip if already hex-only (8 chars)
      next if user.public_slug&.match?(/\A[0-9A-F]{8}\z/)

      new_slug = nil
      loop do
        new_slug = SecureRandom.hex(4).upcase
        break unless User.exists?(public_slug: new_slug)
      end
      user.update_columns(public_slug: new_slug)
    end
  end
end
