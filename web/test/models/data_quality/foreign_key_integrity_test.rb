require "test_helper"

class ForeignKeyIntegrityTest < ActiveSupport::TestCase
  setup do
    @company = Company.create!(name: "Test Company", region: "US")
    @recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    @user = User.create!(email_hmac: "test_hmac", role: "candidate")
  end

  test "experience requires valid interaction" do
    experience = Experience.new(interaction_id: 99999, rating: 5, status: "pending")
    refute experience.save, "Should not save experience with non-existent interaction"
  end

  test "interaction requires valid recruiter" do
    interaction = Interaction.new(recruiter_id: 99999, target_id: @user.id, status: "pending")
    refute interaction.save, "Should not save interaction with non-existent recruiter"
  end

  test "interaction requires valid target user" do
    interaction = Interaction.new(recruiter_id: @recruiter.id, target_id: 99999, status: "pending")
    refute interaction.save, "Should not save interaction with non-existent user"
  end

  test "recruiter foreign key nullification on company deletion" do
    recruiter = Recruiter.create!(name: "Test Recruiter", company: @company)
    company_id = recruiter.company_id
    
    @company.destroy
    recruiter.reload
    
    assert_nil recruiter.company_id, "Recruiter company_id should be nullified"
    refute recruiter.company.present?, "Recruiter should not have a company association"
  end

  test "experience deletion cascades with interaction" do
    interaction = Interaction.create!(recruiter: @recruiter, target: @user)
    experience = Experience.create!(interaction: interaction, rating: 5, status: "pending")
    
    interaction.destroy
    assert_raises(ActiveRecord::RecordNotFound) { Experience.find(experience.id) }
  end
end