class AddPaintCatalogSourceMetadata < ActiveRecord::Migration[8.1]
  def change
    add_column :paint_catalog_runs, :source_metadata, :json, null: false, default: {}
  end
end
