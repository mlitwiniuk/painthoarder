class CreatePaintCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :paint_catalog_runs do |t|
      t.string :source, null: false
      t.string :status, null: false, default: "queued"
      t.json :snapshot, null: false, default: []
      t.json :warnings, null: false, default: []
      t.json :exclusions, null: false, default: []
      t.text :error_message
      t.datetime :finished_at
      t.timestamps
    end
    add_index :paint_catalog_runs, [:source, :created_at]
    add_index :paint_catalog_runs, :source, unique: true,
      where: "status IN ('queued', 'running')", name: "one_active_paint_catalog_run"

    create_table :paint_catalog_records do |t|
      t.string :source, null: false
      t.string :external_id, null: false
      t.references :paint, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :source_url, null: false
      t.json :payload, null: false, default: {}
      t.json :aliases, null: false, default: []
      t.datetime :last_seen_at, null: false
      t.timestamps
    end
    add_index :paint_catalog_records, [:source, :external_id], unique: true
    add_index :paint_catalog_records, [:source, :paint_id], unique: true

    create_table :paint_catalog_entries do |t|
      t.references :paint_catalog_run, null: false, foreign_key: true
      t.references :paint, foreign_key: true
      t.string :external_id, null: false
      t.string :action, null: false
      t.string :status, null: false, default: "pending"
      t.json :payload, null: false, default: {}
      t.json :baseline, null: false, default: {}
      t.json :candidate_ids, null: false, default: []
      t.references :reviewed_by, foreign_key: {to_table: :users}
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :paint_catalog_entries, [:paint_catalog_run_id, :external_id], unique: true,
      name: "paint_catalog_entries_identity"
    add_column :paints, :color_source, :string, null: false, default: "legacy_dataset"
  end
end
