class ReslugRecruitersToHex < ActiveRecord::Migration[8.1]
  def up
    Recruiter.find_each do |recruiter|
      # Skip if already hex-only (8 chars)
      next if recruiter.public_slug.match?(/\A[0-9A-F]{8}\z/)

      new_slug = nil
      loop do
        new_slug = SecureRandom.hex(4).upcase
        break unless Recruiter.exists?(public_slug: new_slug)
      end
      # Use update_columns to bypass validations if necessary, but we want uniqueness check
      # But since we check existence in loop, update_columns is safe and faster, avoiding callbacks
      recruiter.update_columns(public_slug: new_slug)
    end
  end

end
