class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    # Prevent duplicate likes - a user can only like a post once
    add_index :likes, [:user_id, :post_id], unique: true
  end
end
