class AddSlugToBrands < ActiveRecord::Migration[8.1]
  def up
    add_column :brands, :slug, :string
    add_index :brands, :slug, unique: true

    Brand.reset_column_information
    Brand.find_each(&:save!)
  end

  def down
    remove_index :brands, :slug
    remove_column :brands, :slug
  end
end
