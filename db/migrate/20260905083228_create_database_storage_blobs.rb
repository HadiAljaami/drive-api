class CreateDatabaseStorageBlobs < ActiveRecord::Migration[8.1]
  def change
  create_table :database_storage_blobs do |t|
    t.references :blob, null: false, foreign_key: true, index: { unique: true }
    t.binary :data, null: false
    t.datetime :created_at, null: false
  end
  end
end
