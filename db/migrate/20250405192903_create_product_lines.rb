class CreateProductLines < ActiveRecord::Migration[8.0]
  def change
    create_table :product_lines do |t|
      t.string :name
      t.text :description
      t.references :brand, null: false, foreign_key: true

      t.timestamps
    end
  end
end
