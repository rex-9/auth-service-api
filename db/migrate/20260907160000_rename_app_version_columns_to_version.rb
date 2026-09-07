# db/migrate/20260907160000_rename_app_version_columns_to_version.rb

class RenameAppVersionColumnsToVersion < ActiveRecord::Migration[8.1]
  def change
    rename_column :feedbacks, :app_version, :version
    rename_column :log_clients, :app_version, :version
  end
end
