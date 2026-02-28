FactoryBot.define do
  factory :video_paint do
    association :video
    paint { nil }
    sequence(:brand_name) { |n| "Brand #{n}" }
    sequence(:paint_name) { |n| "Paint Name #{n}" }
    paint_code { "P001" }
    paint_type { "base" }
    hex_color { "#808080" }
    product_line_name { "Base" }
    timestamp { "2:30" }
    context { "base coat for armor" }

    trait :matched do
      association :paint
    end

    trait :unmatched do
      paint { nil }
    end
  end
end
