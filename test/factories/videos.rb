FactoryBot.define do
  factory :video do
    association :user, factory: :confirmed_user
    sequence(:youtube_video_id) { |n| "dQw4w9WgXc#{n}" }
    title { "Painting Tutorial" }
    author_name { "Test Channel" }
    thumbnail_url { "https://img.youtube.com/vi/#{youtube_video_id}/maxresdefault.jpg" }
    status { :pending }

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      processed_at { Time.current }
    end

    trait :failed do
      status { :failed }
      error_message { "Analysis failed: timeout" }
    end

    trait :with_paints do
      completed
      after(:create) do |video|
        create_list(:video_paint, 3, video: video)
      end
    end
  end
end
