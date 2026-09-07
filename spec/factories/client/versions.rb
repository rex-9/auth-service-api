FactoryBot.define do
  factory :version, class: "Client::Version" do
    sequence(:number) { |n| "1.0.#{n}" }
    title { "Release" }
    description { "Release notes" }
    status { VersionConstants::Status::DRAFT }
    is_force_update { false }

    trait :published do
      status { VersionConstants::Status::PUBLISHED }
    end

    trait :yanked do
      status { VersionConstants::Status::YANKED }
      released_at { 1.day.ago }
    end

    trait :force do
      is_force_update { true }
    end
  end
end
