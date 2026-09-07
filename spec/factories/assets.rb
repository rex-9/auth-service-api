require "faker"

FactoryBot.define do
  factory :asset do
    sequence(:name) { |n| "asset_file_#{n}" }
    sequence(:url) { |n| "https://example.com/asset_#{n}.jpg" }
    type { "avatar" }
    format { "image" }
    size_bytes { 1024 }
    duration_secs { nil }
    source { "upload" }
    sequence(:storage_key) do |n|
      prefix = defined?(Asset) ? Asset.current_folder_prefix : nil
      prefix.present? ? "#{prefix}/avatar/asset_file_#{n}" : "avatar/asset_file_#{n}"
    end
    association :creator, factory: :user
    assetable_type { "User" }
    assetable_id { creator&.id || SecureRandom.uuid }
  end
end
