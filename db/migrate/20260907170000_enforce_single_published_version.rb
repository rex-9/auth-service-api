# db/migrate/20260907170000_enforce_single_published_version.rb

class EnforceSinglePublishedVersion < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE versions
      SET status = 'yanked', updated_at = CURRENT_TIMESTAMP
      WHERE discarded_at IS NULL
        AND status = 'published'
        AND id <> (
          SELECT id FROM versions
          WHERE discarded_at IS NULL AND status = 'published'
          ORDER BY released_at DESC NULLS LAST, created_at DESC
          LIMIT 1
        )
    SQL

    add_index :versions, :status, unique: true,
              where: "status = 'published' AND discarded_at IS NULL",
              name: "index_versions_on_one_published_kept"
  end

  def down
    remove_index :versions, name: "index_versions_on_one_published_kept"
  end
end
