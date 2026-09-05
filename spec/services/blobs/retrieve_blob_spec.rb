# spec/services/blobs/retrieve_blob_spec.rb
require "rails_helper"

RSpec.describe Blobs::RetrieveBlob do
  it "retrieves data from the backend used when the blob was stored" do
    blob = create(:blob, external_id: "hello.txt", size_bytes: 5, storage_backend: "database")
    backend = instance_double(Storage::Backends::DatabaseBackend, get: "hello")
    factory = class_double(Storage::BackendFactory, build: backend)

    result = described_class.new(storage_backend_factory: factory).call(external_id: blob.external_id)

    expect(factory).to have_received(:build).with("database")
    expect(result[:id]).to eq("hello.txt")
    expect(result[:data]).to eq("aGVsbG8=")
    expect(result[:size]).to eq(5)
    expect(result[:created_at]).to be_present
  end

  it "rejects invalid id type" do
    expect {
      described_class.new.call(external_id: 123)
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("invalid_id") }
  end

  it "rejects blank id" do
    expect {
      described_class.new.call(external_id: "")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("missing_id") }
  end
end