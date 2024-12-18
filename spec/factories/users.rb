require 'faker'

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "username#{n}" }
    name { "Test User" }
    password { "password" }
    password_confirmation { "password" }
    provider { "email" }
    bio { "Hi, It's me!" }
  end
end
