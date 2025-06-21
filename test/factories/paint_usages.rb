# == Schema Information
#
# Table name: paint_usages
#
#  id                :integer          not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  project_update_id :integer          not null
#  user_paint_id     :integer          not null
#
# Indexes
#
#  index_paint_usages_on_project_update_id  (project_update_id)
#  index_paint_usages_on_user_paint_id      (user_paint_id)
#
# Foreign Keys
#
#  project_update_id  (project_update_id => project_updates.id) ON DELETE => cascade
#  user_paint_id      (user_paint_id => user_paints.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :paint_usage do
    project_update { nil }
    user_paint { nil }
  end
end
