# db/migrate/20260907150000_rename_app_installs_to_user_versions.rb

class RenameAppInstallsToUserVersions < ActiveRecord::Migration[8.1]
  def change
    rename_table :app_installs, :user_versions

    {
      "index_app_installs_on_created_by_id" => "index_user_versions_on_created_by_id",
      "index_app_installs_on_discarded_at" => "index_user_versions_on_discarded_at",
      "index_app_installs_on_discarded_by_id" => "index_user_versions_on_discarded_by_id",
      "index_app_installs_on_last_seen_at" => "index_user_versions_on_last_seen_at",
      "index_app_installs_on_number" => "index_user_versions_on_number",
      "index_app_installs_on_undiscarded_by_id" => "index_user_versions_on_undiscarded_by_id",
      "index_app_installs_on_updated_by_id" => "index_user_versions_on_updated_by_id",
      "index_app_installs_on_user_id" => "index_user_versions_on_user_id",
      "index_app_installs_on_user_id_and_platform_kept" => "index_user_versions_on_user_id_and_platform_kept",
      "index_app_installs_on_version_id" => "index_user_versions_on_version_id"
    }.each do |old_name, new_name|
      rename_index :user_versions, old_name, new_name if index_name_exists?(:user_versions, old_name)
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE iam_permissions
          SET resource = 'user_versions',
              name = REPLACE(name, '_app_installs', '_user_versions')
          WHERE resource = 'app_installs'
        SQL
      end
      dir.down do
        execute <<~SQL
          UPDATE iam_permissions
          SET resource = 'app_installs',
              name = REPLACE(name, '_user_versions', '_app_installs')
          WHERE resource = 'user_versions'
        SQL
      end
    end
  end
end
