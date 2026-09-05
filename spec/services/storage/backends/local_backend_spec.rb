require "rails_helper"
require "fileutils"

RSpec.describe Storage::Backends::LocalBackend do
  let(:root_path) { Rails.root.join("tmp", "spec-storage", SecureRandom.hex(8)) }
  let(:backend) { described_class.new(root_path: root_path.to_s) }

  after { FileUtils.rm_rf(root_path) }

  it "has a backend name" do
    expect(backend.name).to eq("local")
  end

  it "stores and retrieves blob data" do
    blob = build(:blob, external_id: "folder/hello.txt")

    backend.put(blob: blob, data: "hello")

    expect(backend.get(blob: blob)).to eq("hello")
    expect(root_path.join("folder", "hello.txt")).not_to exist
  end

  it "raises when stored data is missing" do
    blob = build(:blob, external_id: "missing.txt")

    expect {
      backend.get(blob: blob)
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("blob_data_not_found") }
  end
end