class AutomatePaintCatalog < ActiveRecord::Migration[8.1]
  def change
    # Existing snapshots remain previews; only new refreshes publish by default.
    add_column :paint_catalog_runs, :auto_apply, :boolean, null: false, default: false
    change_column_default :paint_catalog_runs, :auto_apply, from: false, to: true
    add_column :paint_catalog_runs, :automation_status, :string, null: false, default: "pending"
    add_column :paint_catalog_runs, :automation_error, :text
    add_column :paint_catalog_entries, :application_method, :string
    add_column :paint_catalog_entries, :automation_reason, :string
  end
end
