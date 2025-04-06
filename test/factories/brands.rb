# == Schema Information
#
# Table name: brands
#
#  id         :integer          not null, primary key
#  name       :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_brands_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "Brand #{n}" }
    url { "https://example.com" }

    trait :with_logo do
      after(:build) do |brand|
        brand.logo.attach(
          io: File.open(Rails.root.join('test', 'fixtures', 'files', '1px.png')),
          filename: '1px.png',
          content_type: 'image/png'
        )
      end
    end
  end
end
