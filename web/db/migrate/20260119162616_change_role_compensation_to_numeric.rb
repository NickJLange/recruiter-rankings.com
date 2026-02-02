class ChangeRoleCompensationToNumeric < ActiveRecord::Migration[8.1]
  def change
    remove_column :roles, :compensation_range, :string
    add_column :roles, :min_compensation, :integer
    add_column :roles, :max_compensation, :integer
  end
end
