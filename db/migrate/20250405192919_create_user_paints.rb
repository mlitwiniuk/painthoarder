class CreateUserPaints < ActiveRecord::Migration[8.0]
  def change
    create_table :user_paints do |t|
      t.integer :status
      t.text :notes
      t.date :purchase_date
      t.decimal :purchase_price
      t.references :paint, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
