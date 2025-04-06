# == Schema Information
#
# Table name: user_paints
#
#  id             :integer          not null, primary key
#  notes          :text
#  purchase_date  :date
#  purchase_price :decimal(, )
#  status         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  paint_id       :integer          not null
#  user_id        :integer          not null
#
# Indexes
#
#  index_user_paints_on_paint_id  (paint_id)
#  index_user_paints_on_user_id   (user_id)
#
# Foreign Keys
#
#  paint_id  (paint_id => paints.id)
#  user_id   (user_id => users.id)
#
FactoryBot.define do
  factory :user_paint do
    status { :owned }
    notes { "My favorite paint" }
    purchase_date { Date.today - 30.days }
    purchase_price { 3.99 }
    association :paint
    association :user

    trait :wishlist do
      status { :wishlist }
      purchase_date { nil }
      purchase_price { nil }
    end

    trait :avoid do
      status { :avoid }
      purchase_date { nil }
      purchase_price { nil }
    end
  end
end
