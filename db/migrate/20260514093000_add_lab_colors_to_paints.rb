class AddLabColorsToPaints < ActiveRecord::Migration[8.1]
  def up
    add_column :paints, :lab_l, :float
    add_column :paints, :lab_a, :float
    add_column :paints, :lab_b, :float
    add_index :paints, [:lab_l, :lab_a, :lab_b], name: "index_paints_on_lab"

    Paint.reset_column_information
    Paint.find_each do |paint|
      l, a, b = ColorMath.rgb_to_lab(paint.red, paint.green, paint.blue)
      paint.update_columns(lab_l: l, lab_a: a, lab_b: b)
    end
  end

  def down
    remove_index :paints, name: "index_paints_on_lab"
    remove_column :paints, :lab_l
    remove_column :paints, :lab_a
    remove_column :paints, :lab_b
  end
end
