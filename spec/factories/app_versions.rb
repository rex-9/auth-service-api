FactoryBot.define do
  factory :app_version do
    sequence(:number) { |n| "1.0.#{n}" }
    title { "Release" }
    description { "Release notes" }
    status { AppVersionConstants::Status::DRAFT }
    is_force_update { false }

    trait :published do
      status { AppVersionConstants::Status::PUBLISHED }
    end

    trait :yanked do
      status { AppVersionConstants::Status::YANKED }
      released_at { 1.day.ago }
    end

    trait :force do
      is_force_update { true }
    end
  end
end
