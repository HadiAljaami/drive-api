class Blob < ApplicationRecord
  has_one :database_storage_blob, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :size_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :storage_backend, presence: true
end
