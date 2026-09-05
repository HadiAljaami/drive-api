require "rails_helper"

RSpec.describe Storage::BackendFactory do
  it "builds database backend" do
    expect(described_class.build("database")).to be_a(Storage::Backends::DatabaseBackend)
  end

  it "builds local backend" do
    expect(described_class.build("local")).to be_a(Storage::Backends::LocalBackend)
  end

  it "rejects unsupported backend" do
    expect {
      described_class.build("unknown")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("unsupported_storage_backend") }
  end
end