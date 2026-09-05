class DatabaseStorageBlob < ApplicationRecord
  belongs_to :blob

  validates :data, presence: true
end
