class CreateProductLineSimilarities < ActiveRecord::Migration[8.1]
  def change
    create_table :product_line_similarities do |t|
      t.references :product_line, null: false, foreign_key: true
      t.references :similar_product_line, null: false, foreign_key: {to_table: :product_lines}

      t.timestamps
    end

    add_index :product_line_similarities, [:product_line_id, :similar_product_line_id],
      unique: true, name: "idx_product_line_similarities_unique"
  end
end
