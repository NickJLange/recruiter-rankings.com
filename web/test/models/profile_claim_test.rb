require "test_helper"

class ProfileClaimTest < ActiveSupport::TestCase
  setup do
    @recruiter = recruiters(:one)
    @user = users(:one)
  end

  test "valid profile claim with li method" do
    claim = ProfileClaim.new(
      recruiter: @recruiter,
      user: @user,
      verification_method: "li"
    )
    assert claim.valid?
  end

  test "valid profile claim with email method" do
    claim = ProfileClaim.new(
      recruiter: @recruiter,
      user: @user,
      verification_method: "email"
    )
    assert claim.valid?
  end

  test "invalid without recruiter" do
    claim = ProfileClaim.new(
      user: @user,
      verification_method: "li"
    )
    assert_not claim.valid?
  end

  test "invalid without user" do
    claim = ProfileClaim.new(
      recruiter: @recruiter,
      verification_method: "li"
    )
    assert_not claim.valid?
  end

  test "invalid with unknown verification_method" do
    assert_raises(ArgumentError) do
      ProfileClaim.new(
        recruiter: @recruiter,
        user: @user,
        verification_method: "phone"
      )
    end
  end

  test "verification_method enum values" do
    assert_equal({ "li" => "li", "email" => "email" }, ProfileClaim.verification_methods)
  end

  test "verified_at tracks verification time" do
    claim = ProfileClaim.create!(
      recruiter: @recruiter,
      user: @user,
      verification_method: "li"
    )
    assert_nil claim.verified_at
    claim.update!(verified_at: Time.current)
    assert_not_nil claim.reload.verified_at
  end

  test "revoked_at tracks revocation time" do
    claim = ProfileClaim.create!(
      recruiter: @recruiter,
      user: @user,
      verification_method: "li"
    )
    assert_nil claim.revoked_at
    claim.update!(revoked_at: Time.current)
    assert_not_nil claim.reload.revoked_at
  end

  test "unique constraint on recruiter and user" do
    ProfileClaim.create!(
      recruiter: @recruiter,
      user: @user,
      verification_method: "li"
    )
    duplicate = ProfileClaim.new(
      recruiter: @recruiter,
      user: @user,
      verification_method: "email"
    )
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end
end
