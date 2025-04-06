class CreatePaints < ActiveRecord::Migration[8.0]
  def change
    create_table :paints do |t|
      t.string :name
      t.string :code
      t.integer :red
      t.integer :green
      t.integer :blue
      t.string :hex_color
      t.references :product_line, null: false, foreign_key: true

      t.timestamps
    end
  end
end
