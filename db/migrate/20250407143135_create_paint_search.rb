class CreatePaintSearch < ActiveRecord::Migration[8.0]
  def up
    execute("CREATE VIRTUAL TABLE fts_paints USING fts5(name, code, brand_name, product_line_name, paint_id)")
  end

  def down
    execute("DROP TABLE IF EXISTS fts_paints")
  end
end
