require "rails_helper"

RSpec.describe Storage::Backends::DatabaseBackend do
  subject(:backend) { described_class.new }

  it "has a backend name" do
    expect(backend.name).to eq("database")
  end

  it "stores and retrieves blob data" do
    blob = create(:blob)

    backend.put(blob: blob, data: "hello")

    expect(backend.get(blob: blob)).to eq("hello")
  end

  it "raises when stored data is missing" do
    blob = create(:blob)

    expect {
      backend.get(blob: blob)
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("blob_data_not_found") }
  end
end