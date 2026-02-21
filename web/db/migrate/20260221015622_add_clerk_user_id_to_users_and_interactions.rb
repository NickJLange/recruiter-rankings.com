class AddClerkUserIdToUsersAndInteractions < ActiveRecord::Migration[8.1]
  def change
    # Link local User records to their Clerk identity (for audit logging and admin lookup).
    add_column :users, :clerk_user_id, :string
    add_index :users, :clerk_user_id, unique: true

    # Store the Clerk user ID of the person who submitted each interaction/review,
    # replacing the EmailIdentityService implicit-user creation pattern.
    add_column :interactions, :clerk_user_id, :string
    add_index :interactions, :clerk_user_id
  end
end
