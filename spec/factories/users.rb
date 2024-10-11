require 'faker'

FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { "password" }
    provider { "email" }
    photo { 'https://www.google.com/' }
  end
end
