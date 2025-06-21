class CreatePaintUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :paint_usages do |t|
      t.references :project_update, null: false, foreign_key: {on_delete: :cascade}
      t.references :user_paint, null: false, foreign_key: {on_delete: :cascade}

      t.timestamps
    end
  end
end
