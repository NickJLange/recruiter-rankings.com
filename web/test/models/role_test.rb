require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "formatted_compensation returns nil if incomplete" do
    role = Role.new
    assert_nil role.formatted_compensation
    
    role.min_compensation = 100000
    assert_nil role.formatted_compensation
  end

  test "formatted_compensation formats correctly" do
    role = Role.new(min_compensation: 120500, max_compensation: 155200)
    # 120500 / 1000.0 = 120.5
    # 155200 / 1000.0 = 155.2
    assert_equal "$120.5K - $155.2K", role.formatted_compensation
  end

  test "formatted_compensation handles round numbers" do
    role = Role.new(min_compensation: 120000, max_compensation: 150000)
    # 120.0
    assert_equal "$120.0K - $150.0K", role.formatted_compensation
  end
end
