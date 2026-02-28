class AddSlugToVideos < ActiveRecord::Migration[8.1]
  def up
    add_column :videos, :slug, :string
    add_index :videos, :slug, unique: true

    Video.reset_column_information
    Video.find_each(&:save!)
  end

  def down
    remove_index :videos, :slug
    remove_column :videos, :slug
  end
end
