class AddSlugToPaints < ActiveRecord::Migration[8.1]
  def change
    add_column :paints, :slug, :string
    add_index :paints, [:product_line_id, :slug], unique: true

    reversible do |dir|
      dir.up do
        Paint.find_each(&:save!)
      end
    end
  end
end
