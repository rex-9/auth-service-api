class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name
      t.string :provider
      t.string :photo
    end
  end
end