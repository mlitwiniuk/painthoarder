# == Schema Information
#
# Table name: paints
#
#  id              :integer          not null, primary key
#  blue            :integer
#  code            :string
#  green           :integer
#  hex_color       :string
#  name            :string
#  red             :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_line_id :integer          not null
#
# Indexes
#
#  index_paints_on_product_line_id  (product_line_id)
#
# Foreign Keys
#
#  product_line_id  (product_line_id => product_lines.id)
#
FactoryBot.define do
  factory :paint do
    sequence(:name) { |n| "Paint #{n}" }
    sequence(:code) { |n| "P#{n}" }
    red { 128 }
    green { 128 }
    blue { 128 }
    association :product_line

    trait :with_image do
      after(:build) do |paint|
        paint.image.attach(
          io: File.open(Rails.root.join('test', 'fixtures', 'files', '1px.png')),
          filename: '1px.png',
          content_type: 'image/png'
        )
      end
    end

    # Color variants for testing
    factory :red_paint do
      red { 255 }
      green { 0 }
      blue { 0 }
    end

    factory :green_paint do
      red { 0 }
      green { 255 }
      blue { 0 }
    end
  end
end
