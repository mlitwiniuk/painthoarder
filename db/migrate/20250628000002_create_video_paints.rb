class CreateVideoPaints < ActiveRecord::Migration[8.1]
  def change
    create_table :video_paints do |t|
      t.references :video, null: false, foreign_key: {on_delete: :cascade}
      t.references :paint, null: true, foreign_key: true
      t.string :brand_name
      t.string :paint_name
      t.string :paint_code
      t.string :paint_type
      t.string :hex_color
      t.string :product_line_name
      t.string :timestamp
      t.string :context

      t.timestamps
    end
  end
end
