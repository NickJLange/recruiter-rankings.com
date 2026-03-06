namespace :data do
  namespace :retention do
    desc "Delete expired, unverified identity challenges"
    task cleanup: :environment do
      count = IdentityChallenge
        .where("expires_at < ?", Time.current)
        .where(verified_at: nil)
        .delete_all
      puts "Deleted #{count} expired, unverified identity challenge(s)."
    end
  end
end
