# db/migrate/20260907140000_rename_app_versions_to_versions.rb

class RenameAppVersionsToVersions < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :app_installs, :app_versions

    rename_table :app_versions, :versions

    {
      "index_app_versions_on_android_build_number_kept" => "index_versions_on_android_build_number_kept",
      "index_app_versions_on_created_by_id" => "index_versions_on_created_by_id",
      "index_app_versions_on_discarded_at" => "index_versions_on_discarded_at",
      "index_app_versions_on_discarded_by_id" => "index_versions_on_discarded_by_id",
      "index_app_versions_on_ios_build_number_kept" => "index_versions_on_ios_build_number_kept",
      "index_app_versions_on_number_kept" => "index_versions_on_number_kept",
      "index_app_versions_on_released_at" => "index_versions_on_released_at",
      "index_app_versions_on_status" => "index_versions_on_status",
      "index_app_versions_on_undiscarded_by_id" => "index_versions_on_undiscarded_by_id",
      "index_app_versions_on_updated_by_id" => "index_versions_on_updated_by_id"
    }.each do |old_name, new_name|
      rename_index :versions, old_name, new_name if index_name_exists?(:versions, old_name)
    end

    rename_column :app_installs, :app_version_id, :version_id
    if index_name_exists?(:app_installs, "index_app_installs_on_app_version_id")
      rename_index :app_installs, "index_app_installs_on_app_version_id", "index_app_installs_on_version_id"
    end
    add_foreign_key :app_installs, :versions, column: :version_id, on_delete: :nullify

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE iam_permissions
          SET resource = 'versions',
              name = REPLACE(name, '_app_versions', '_versions')
          WHERE resource = 'app_versions'
        SQL
      end
      dir.down do
        execute <<~SQL
          UPDATE iam_permissions
          SET resource = 'app_versions',
              name = REPLACE(name, '_versions', '_app_versions')
          WHERE resource = 'versions'
        SQL
      end
    end
  end
end
