require "test_helper"

class IdentityChallengeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid identity challenge" do
    challenge = IdentityChallenge.new(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.from_now
    )
    assert challenge.valid?
  end

  test "invalid without token_hash" do
    challenge = IdentityChallenge.new(
      subject: @user,
      token_hash: nil,
      expires_at: 1.hour.from_now
    )
    assert_not challenge.valid?
    assert_includes challenge.errors[:token_hash], "can't be blank"
  end

  test "invalid without expires_at" do
    challenge = IdentityChallenge.new(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: nil
    )
    assert_not challenge.valid?
    assert_includes challenge.errors[:expires_at], "can't be blank"
  end

  test "invalid without subject" do
    challenge = IdentityChallenge.new(
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.from_now
    )
    assert_not challenge.valid?
  end

  test "polymorphic subject can be a User" do
    challenge = IdentityChallenge.create!(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.from_now
    )
    assert_equal "User", challenge.subject_type
    assert_equal @user.id, challenge.subject_id
  end

  test "polymorphic subject can be a Recruiter" do
    recruiter = recruiters(:one)
    challenge = IdentityChallenge.create!(
      subject: recruiter,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.from_now
    )
    assert_equal "Recruiter", challenge.subject_type
    assert_equal recruiter.id, challenge.subject_id
  end

  test "expired challenge detected by expires_at" do
    challenge = IdentityChallenge.create!(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.ago
    )
    assert challenge.expires_at < Time.current
  end

  test "verified_at can be set" do
    challenge = IdentityChallenge.create!(
      subject: @user,
      token_hash: SecureRandom.hex(32),
      expires_at: 1.hour.from_now
    )
    assert_nil challenge.verified_at
    challenge.update!(verified_at: Time.current)
    assert_not_nil challenge.reload.verified_at
  end

  test "token_hash uniqueness enforced at database level" do
    hash = SecureRandom.hex(32)
    IdentityChallenge.create!(
      subject: @user,
      token_hash: hash,
      expires_at: 1.hour.from_now
    )
    duplicate = IdentityChallenge.new(
      subject: @user,
      token_hash: hash,
      expires_at: 2.hours.from_now
    )
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end
end
