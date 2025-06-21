class CreateProjectUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :project_updates do |t|
      t.references :project, null: false, foreign_key: {on_delete: :cascade}
      t.integer :position
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
