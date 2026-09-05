require "rails_helper"

RSpec.describe Storage::S3::Configuration do
  it "builds configuration from valid values" do
    configuration = described_class.new(
      endpoint: "http://localhost:9000",
      region: "us-east-1",
      bucket: "drive",
      access_key_id: "access-key",
      secret_access_key: "secret-key"
    )

    expect(configuration.endpoint_uri.host).to eq("localhost")
    expect(configuration.region).to eq("us-east-1")
    expect(configuration.bucket).to eq("drive")
  end

  it "rejects missing configuration" do
    expect {
      described_class.new(
        endpoint: nil,
        region: "us-east-1",
        bucket: "drive",
        access_key_id: "access-key",
        secret_access_key: "secret-key"
      )
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("storage_error") }
  end

  it "rejects invalid endpoint" do
    expect {
      described_class.new(
        endpoint: "not a url",
        region: "us-east-1",
        bucket: "drive",
        access_key_id: "access-key",
        secret_access_key: "secret-key"
      )
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("storage_error") }
  end
end