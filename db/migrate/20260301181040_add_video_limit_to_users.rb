class AddVideoLimitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :video_limit, :integer, default: 1, null: false
  end
end
