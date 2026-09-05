require "rails_helper"

RSpec.describe Storage::Backends::S3HttpBackend do
  let(:configuration) do
    Storage::S3::Configuration.new(
      endpoint: "http://s3.test:9000",
      region: "us-east-1",
      bucket: "drive",
      access_key_id: "test-access",
      secret_access_key: "test-secret"
    )
  end

  let(:http_client) { instance_double(Storage::S3::HttpClient) }
  let(:backend) { described_class.new(configuration: configuration, http_client: http_client) }
  let(:blob) { build(:blob, external_id: "folder/hello.txt") }

  it "has a backend name" do
    expect(backend.name).to eq("s3")
  end

  it "stores data using the derived object key" do
    expect(http_client).to receive(:put).with(
      key: Storage::S3::ObjectKey.call("folder/hello.txt"),
      body: "hello"
    )

    backend.put(blob: blob, data: "hello")
  end

  it "retrieves data using the derived object key" do
    expect(http_client).to receive(:get)
      .with(key: Storage::S3::ObjectKey.call("folder/hello.txt"))
      .and_return("hello")

    expect(backend.get(blob: blob)).to eq("hello")
  end
end