require "test_helper"

class ConstraintValidationTest < ActiveSupport::TestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @user = User.create!(email_hmac: "test_hmac", role: "candidate")
  end

  test "database check constraint prevents invalid rating" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user)
    
    assert_raises(ActiveRecord::StatementInvalid) do
      Experience.connection.execute(
        "INSERT INTO experiences (rating, interaction_id, created_at, updated_at, status) VALUES (10, #{interaction.id}, NOW(), NOW(), 'pending')"
      )
    end
  end

  test "database check constraint prevents invalid user role enum" do
    assert_raises(ArgumentError) do
      User.create!(email_hmac: SecureRandom.hex(16), role: "invalid_role")
    end
  end

  test "unique constraint on email_hmac enforces single user per email" do
    user1 = User.create!(email_hmac: "same_hmac", role: "candidate")
    
    assert_raises(ActiveRecord::RecordNotUnique) do
      User.connection.execute(
        "INSERT INTO users (email_hmac, role, created_at, updated_at) VALUES ('same_hmac', 'candidate', NOW(), NOW())"
      )
    end
  end

  test "unique constraint on recruiter public_slug" do
    slug = SecureRandom.hex(4).upcase
    Recruiter.create!(name: "Recruiter 1", public_slug: slug, company: @company)
    
    assert_raises(ActiveRecord::RecordNotUnique) do
      Recruiter.connection.execute(
        "INSERT INTO recruiters (name, public_slug, created_at, updated_at) VALUES ('Recruiter 2', '#{slug}', NOW(), NOW())"
      )
    end
  end

  test "model validates experience status presence" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user)
    experience = Experience.new(interaction: interaction, rating: 5, status: nil)
    
    refute experience.valid?, "Experience should require status presence"
    assert_includes experience.errors[:status], "can't be blank"
  end

  test "enum validation prevents invalid profile_claim verification_method" do
    assert_raises(ArgumentError) do
      ProfileClaim.create!(
        recruiter_id: @recruiter.id,
        user_id: @user.id,
        verification_method: "invalid_method"
      )
    end
  end
end