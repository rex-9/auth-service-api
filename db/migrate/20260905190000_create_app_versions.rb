# db/migrate/20260905190000_create_app_versions.rb
class CreateAppVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :app_versions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :number, null: false
      t.string :title, null: false
      t.text :description
      t.boolean :is_force_update, null: false, default: false
      t.string :status, null: false, default: AppVersionConstants::Status::DRAFT
      t.datetime :released_at
      t.integer :ios_build_number
      t.integer :android_build_number
      t.string :ios_store_url
      t.string :android_store_url

      t.references :created_by, type: :uuid, foreign_key: { to_table: :users }
      t.references :updated_by, type: :uuid, foreign_key: { to_table: :users }
      t.references :discarded_by, type: :uuid, foreign_key: { to_table: :users }
      t.references :undiscarded_by, type: :uuid, foreign_key: { to_table: :users }

      t.datetime :discarded_at
      t.datetime :undiscarded_at

      t.timestamps
    end

    add_index :app_versions, :number, unique: true, where: "discarded_at IS NULL",
              name: "index_app_versions_on_number_kept"
    add_index :app_versions, :ios_build_number, unique: true,
              where: "discarded_at IS NULL AND ios_build_number IS NOT NULL",
              name: "index_app_versions_on_ios_build_number_kept"
    add_index :app_versions, :android_build_number, unique: true,
              where: "discarded_at IS NULL AND android_build_number IS NOT NULL",
              name: "index_app_versions_on_android_build_number_kept"
    add_index :app_versions, :status
    add_index :app_versions, :released_at
    add_index :app_versions, :discarded_at
  end
end
