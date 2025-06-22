# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  content    :text
#  prefrences :json
#  published  :boolean          default(FALSE)
#  slug       :string
#  status     :integer          default("draft"), not null
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_pages_on_slug  (slug) UNIQUE
#
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
