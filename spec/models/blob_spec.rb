require "rails_helper"

RSpec.describe Blob, type: :model do
  subject(:blob) { build(:blob) }

  it { is_expected.to have_one(:database_storage_blob).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to validate_presence_of(:size_bytes) }
  it { is_expected.to validate_numericality_of(:size_bytes).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_presence_of(:storage_backend) }
end