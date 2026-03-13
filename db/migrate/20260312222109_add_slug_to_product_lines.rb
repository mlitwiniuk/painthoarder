class AddSlugToProductLines < ActiveRecord::Migration[8.1]
  def change
    add_column :product_lines, :slug, :string
    add_index :product_lines, [:brand_id, :slug], unique: true

    reversible do |dir|
      dir.up do
        ProductLine.find_each(&:save!)
      end
    end
  end
end
