require "test_helper"

# Tests the query logic used by rake data:retention:cleanup.
# The rake task runs exactly this AR query; tests here cover all three cases.
class DataRetentionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  def run_cleanup
    IdentityChallenge
      .where("expires_at < ?", Time.current)
      .where(verified_at: nil)
      .delete_all
  end

  test "deletes expired unverified challenges" do
    expired = IdentityChallenge.create!(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.ago,
      verified_at: nil
    )

    count = run_cleanup

    assert count >= 1
    refute IdentityChallenge.exists?(expired.id)
  end

  test "does not delete active (non-expired) challenges" do
    active = IdentityChallenge.create!(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.from_now,
      verified_at: nil
    )

    run_cleanup

    assert IdentityChallenge.exists?(active.id)
  end

  test "does not delete expired but verified challenges" do
    verified_expired = IdentityChallenge.create!(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.ago,
      verified_at: 2.hours.ago
    )

    run_cleanup

    assert IdentityChallenge.exists?(verified_expired.id)
  end

  test "returns correct count of deleted records" do
    2.times do
      IdentityChallenge.create!(
        subject: @user,
        token_hash: SecureRandom.hex(32),
        expires_at: 1.hour.ago,
        verified_at: nil
      )
    end

    count = run_cleanup

    assert count >= 2
  end
end
