require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "valid company with name" do
    company = Company.new(name: "Test Corp", region: "US")
    assert company.valid?
  end

  test "invalid without name" do
    company = Company.new(name: nil)
    assert_not company.valid?
    assert_includes company.errors[:name], "can't be blank"
  end

  test "has many recruiters" do
    company = companies(:one)
    assert_respond_to company, :recruiters
  end

  test "has many reviews" do
    company = companies(:one)
    assert_respond_to company, :reviews
  end

  test "nullifies recruiters on destroy" do
    company = Company.create!(name: "Doomed Corp")
    recruiter = Recruiter.create!(name: "Agent Smith", company: company, public_slug: SecureRandom.hex(4).upcase, email_hmac: SecureRandom.hex(16))
    company.destroy!
    assert_nil recruiter.reload.company_id
  end

  test "size_bucket accepts various values" do
    %w[Small Medium Large Enterprise].each do |bucket|
      company = Company.new(name: "Test", size_bucket: bucket)
      assert company.valid?, "Expected #{bucket} to be valid"
    end
  end

  test "size_bucket accepts nil" do
    company = Company.new(name: "Test", size_bucket: nil)
    assert company.valid?
  end
end
