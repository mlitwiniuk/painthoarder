class AddCoverAndPrimaryPhotoToProjectsAndUpdates < ActiveRecord::Migration[8.0]
  def change
    add_reference :projects, :cover_photo, foreign_key: { to_table: :active_storage_attachments, on_delete: :nullify }
    add_reference :project_updates, :primary_photo, foreign_key: { to_table: :active_storage_attachments, on_delete: :nullify }
  end
end
