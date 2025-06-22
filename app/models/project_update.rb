# == Schema Information
#
# Table name: project_updates
#
#  id               :integer          not null, primary key
#  description      :text
#  position         :integer
#  title            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  primary_photo_id :integer
#  project_id       :integer          not null
#
# Indexes
#
#  index_project_updates_on_primary_photo_id  (primary_photo_id)
#  index_project_updates_on_project_id        (project_id)
#
# Foreign Keys
#
#  primary_photo_id  (primary_photo_id => active_storage_attachments.id) ON DELETE => nullify
#  project_id        (project_id => projects.id) ON DELETE => cascade
#
class ProjectUpdate < ApplicationRecord
  acts_as_list scope: :project, column: :position

  belongs_to :project
  belongs_to :primary_photo, class_name: "ActiveStorage::Attachment", optional: true

  has_many_attached :photos
  has_many :paint_usages, dependent: :destroy
  has_many :user_paints, through: :paint_usages

  accepts_nested_attributes_for :paint_usages, allow_destroy: true

  validates :position, numericality: {only_integer: true}, allow_nil: true
  validates :photos, content_type: {in: [:png, :jpeg], spoofing_protection: true}, size: {less_than: 5.megabytes}, total_size: {less_than: 50.megabytes}

  default_scope { order(position: :asc) }
end
