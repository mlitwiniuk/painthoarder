class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :title
      t.text :description
      t.integer :visibility
      t.string :secret_token
      t.references :user, null: false, foreign_key: {on_delete: :cascade}

      t.timestamps
    end
    add_index :projects, :secret_token, unique: true
  end
end
