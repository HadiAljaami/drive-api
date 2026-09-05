class CreateBlobs < ActiveRecord::Migration[8.1]
  def change
  create_table :blobs do |t|
    t.string :external_id, null: false
    t.bigint :size_bytes, null: false
    t.string :storage_backend, null: false
    t.datetime :created_at, null: false
  end

add_index :blobs, :external_id, unique: true
  end
end

# 

