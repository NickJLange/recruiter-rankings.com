class AddUniqueIndexToUsersPublicSlug < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :public_slug, if_exists: true
    add_index :users, :public_slug, unique: true
  end
end
