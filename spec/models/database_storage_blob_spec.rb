require "rails_helper"

RSpec.describe DatabaseStorageBlob, type: :model do
  subject(:database_storage_blob) { build(:database_storage_blob) }

  it { is_expected.to belong_to(:blob) }
  it { is_expected.to validate_presence_of(:data) }
end