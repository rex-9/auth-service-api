# db/migrate/20260905190001_create_app_installs.rb
class CreateAppInstalls < ActiveRecord::Migration[8.1]
  def change
    create_table :app_installs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :platform, null: false
      t.string :number, null: false
      t.integer :build_number
      t.references :app_version, type: :uuid, foreign_key: { on_delete: :nullify }
      t.datetime :last_seen_at, null: false

      t.references :created_by, type: :uuid, foreign_key: { to_table: :users }
      t.references :updated_by, type: :uuid, foreign_key: { to_table: :users }
      t.references :discarded_by, type: :uuid, foreign_key: { to_table: :users }
      t.references :undiscarded_by, type: :uuid, foreign_key: { to_table: :users }

      t.datetime :discarded_at
      t.datetime :undiscarded_at

      t.timestamps
    end

    add_index :app_installs, [ :user_id, :platform ], unique: true, where: "discarded_at IS NULL",
              name: "index_app_installs_on_user_id_and_platform_kept"
    add_index :app_installs, :number
    add_index :app_installs, :last_seen_at
    add_index :app_installs, :discarded_at
  end
end
