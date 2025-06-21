# == Schema Information
#
# Table name: projects
#
#  id             :integer          not null, primary key
#  description    :text
#  secret_token   :string
#  title          :string
#  visibility     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  cover_photo_id :integer
#  user_id        :integer          not null
#
# Indexes
#
#  index_projects_on_cover_photo_id  (cover_photo_id)
#  index_projects_on_secret_token    (secret_token) UNIQUE
#  index_projects_on_user_id         (user_id)
#
# Foreign Keys
#
#  cover_photo_id  (cover_photo_id => active_storage_attachments.id) ON DELETE => nullify
#  user_id         (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :project do
    title { "MyString" }
    description { "MyText" }
    visibility { 1 }
    secret_token { "MyString" }
    user { nil }
  end
end
