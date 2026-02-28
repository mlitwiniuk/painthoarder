class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :videos do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.string :youtube_video_id, null: false
      t.string :title
      t.string :author_name
      t.string :thumbnail_url
      t.integer :status, default: 0, null: false
      t.text :raw_response
      t.text :error_message
      t.datetime :processed_at

      t.timestamps
    end

    add_index :videos, :youtube_video_id, unique: true
    add_index :videos, [:status, :created_at]
  end
end
