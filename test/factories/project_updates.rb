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
FactoryBot.define do
  factory :project_update do
    project { nil }
    position { 1 }
    title { "MyString" }
    description { "MyText" }
  end
end
