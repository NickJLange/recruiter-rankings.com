require "test_helper"

class ExperienceTest < ActiveSupport::TestCase
  setup do
    @interaction = interactions(:one)
  end

  test "valid experience" do
    exp = Experience.new(interaction: @interaction, rating: 3, status: "pending")
    assert exp.valid?
  end

  test "invalid without rating" do
    exp = Experience.new(interaction: @interaction, rating: nil, status: "pending")
    assert_not exp.valid?
    assert_includes exp.errors[:rating], "can't be blank"
  end

  test "invalid without status" do
    exp = Experience.new(interaction: @interaction, rating: 3, status: nil)
    assert_not exp.valid?
    assert_includes exp.errors[:status], "can't be blank"
  end

  test "rating must be between 1 and 5" do
    [1, 2, 3, 4, 5].each do |r|
      exp = Experience.new(interaction: @interaction, rating: r, status: "pending")
      assert exp.valid?, "Expected rating #{r} to be valid"
    end
  end

  test "rating 0 is invalid" do
    exp = Experience.new(interaction: @interaction, rating: 0, status: "pending")
    assert_not exp.valid?
  end

  test "rating 6 is invalid" do
    exp = Experience.new(interaction: @interaction, rating: 6, status: "pending")
    assert_not exp.valid?
  end

  test "belongs to interaction" do
    exp = experiences(:one)
    assert_instance_of Interaction, exp.interaction
  end

  test "has many review_metrics" do
    exp = experiences(:one)
    assert_respond_to exp, :review_metrics
  end

  test "approved_aggregates_by_recruiter returns correct structure" do
    result = Experience.approved_aggregates_by_recruiter
    assert_kind_of ActiveRecord::Relation, result
  end

  test "approved_aggregates_by_company returns correct structure" do
    result = Experience.approved_aggregates_by_company
    assert_kind_of ActiveRecord::Relation, result
  end

  test "default status is pending" do
    exp = Experience.new(interaction: @interaction, rating: 3)
    exp.save!
    assert_equal "pending", exp.reload.status
  end
end
