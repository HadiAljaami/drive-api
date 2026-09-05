require "rails_helper"

RSpec.describe Blobs::CreateBlob do
  class FakeStorageBackend
    attr_reader :stored_blob, :stored_data

    def name
      "fake"
    end

    def put(blob:, data:)
      @stored_blob = blob
      @stored_data = data
    end
  end

  let(:backend) { FakeStorageBackend.new }
  subject(:service) { described_class.new(storage_backend: backend) }

  it "creates metadata and stores decoded data" do
    blob = service.call(external_id: "hello.txt", encoded_data: "aGVsbG8=")

    expect(blob.external_id).to eq("hello.txt")
    expect(blob.size_bytes).to eq(5)
    expect(blob.storage_backend).to eq("fake")
    expect(backend.stored_blob).to eq(blob)
    expect(backend.stored_data).to eq("hello")
  end

  it "rejects invalid id type" do
    expect {
      service.call(external_id: 123, encoded_data: "aGVsbG8=")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("invalid_id") }
  end

  it "rejects blank id" do
    expect {
      service.call(external_id: "", encoded_data: "aGVsbG8=")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("missing_id") }
  end

  it "rejects invalid data type" do
    expect {
      service.call(external_id: "hello.txt", encoded_data: 123)
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("invalid_data") }
  end

  it "rejects blank data" do
    expect {
      service.call(external_id: "hello.txt", encoded_data: "")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("missing_data") }
  end

  it "rejects invalid base64" do
    expect {
      service.call(external_id: "hello.txt", encoded_data: "%%%")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("invalid_base64") }
  end

  it "rejects duplicate external ids" do
    service.call(external_id: "same-id", encoded_data: "aGVsbG8=")

    expect {
      service.call(external_id: "same-id", encoded_data: "aGVsbG8=")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("blob_already_exists") }
  end
end