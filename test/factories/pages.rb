FactoryBot.define do
  factory :page do
    sequence(:title) { |n| "Test Page Title #{n}" } # Ensures uniqueness
    content { "This is sample content for the page with detailed information." }
    status { :draft } # Default status

    # Traits for different statuses
    trait :issued do
      status { :issued }
    end

    trait :archived do
      status { :archived }
    end
  end
end
