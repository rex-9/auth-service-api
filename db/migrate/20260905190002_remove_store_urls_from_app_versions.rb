# db/migrate/20260905190002_remove_store_urls_from_app_versions.rb
class RemoveStoreUrlsFromAppVersions < ActiveRecord::Migration[8.1]
  def change
    remove_column :app_versions, :ios_store_url, :string
    remove_column :app_versions, :android_store_url, :string
  end
end
