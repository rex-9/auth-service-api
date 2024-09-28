FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "test@example.com" }
    password { "password" }
    password_confirmation { "password" }
    provider { "email" }
  end
end
