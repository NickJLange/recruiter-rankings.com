require "test_helper"

class TakedownRequestTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @recruiter = recruiters(:one)
  end

  test "valid takedown request with user subject" do
    tr = TakedownRequest.new(
      subject: @user,
      status: "pending",
      reason_code: "privacy",
      requested_by: "user@example.com"
    )
    assert tr.valid?
  end

  test "valid takedown request with recruiter subject" do
    tr = TakedownRequest.new(
      subject: @recruiter,
      status: "pending",
      reason_code: "inaccurate",
      requested_by: "recruiter@example.com"
    )
    assert tr.valid?
  end

  test "invalid without subject" do
    tr = TakedownRequest.new(
      status: "pending",
      reason_code: "privacy"
    )
    assert_not tr.valid?
  end

  test "invalid with unknown status" do
    assert_raises(ArgumentError) do
      TakedownRequest.new(
        subject: @user,
        status: "unknown",
        reason_code: "privacy"
      )
    end
  end

  test "status enum values" do
    expected = { "pending" => "pending", "in_review" => "in_review", "resolved" => "resolved", "rejected" => "rejected" }
    assert_equal expected, TakedownRequest.statuses
  end

  test "status transitions" do
    tr = TakedownRequest.create!(
      subject: @user,
      status: "pending",
      reason_code: "privacy"
    )
    assert tr.pending?

    tr.update!(status: "in_review")
    assert tr.in_review?

    tr.update!(status: "resolved", resolved_at: Time.current)
    assert tr.resolved?
    assert_not_nil tr.resolved_at
  end

  test "sla_due_at can be set and queried" do
    due = 3.days.from_now
    tr = TakedownRequest.create!(
      subject: @user,
      status: "pending",
      sla_due_at: due
    )
    assert_in_delta due.to_f, tr.sla_due_at.to_f, 1.0
  end

  test "polymorphic subject_type stored correctly" do
    tr = TakedownRequest.create!(subject: @user, status: "pending")
    assert_equal "User", tr.subject_type

    tr2 = TakedownRequest.create!(subject: @recruiter, status: "pending")
    assert_equal "Recruiter", tr2.subject_type
  end

  test "default status from database is pending" do
    tr = TakedownRequest.new(subject: @user)
    tr.save!
    assert_equal "pending", tr.reload.status
  end
end
