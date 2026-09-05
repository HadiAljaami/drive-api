require "rails_helper"

RSpec.describe Storage::S3::Signer do
  let(:configuration) do
    Storage::S3::Configuration.new(
      endpoint: "http://localhost:9000",
      region: "us-east-1",
      bucket: "drive",
      access_key_id: "test-access",
      secret_access_key: "test-secret"
    )
  end

  it "creates AWS Signature Version 4 headers" do
    uri = URI.parse("http://localhost:9000/drive/blobs/ab/key")
    time = Time.utc(2026, 9, 5, 12, 0, 0)

    headers = described_class.new(configuration: configuration).signed_headers(
      method: "PUT",
      uri: uri,
      body: "hello",
      time: time
    )

    expect(headers["host"]).to eq("localhost:9000")
    expect(headers["x-amz-date"]).to eq("20260905T120000Z")
    expect(headers["x-amz-content-sha256"]).to eq(Digest::SHA256.hexdigest("hello"))
    expect(headers["authorization"]).to include("AWS4-HMAC-SHA256")
    expect(headers["authorization"]).to include("Credential=test-access/20260905/us-east-1/s3/aws4_request")
    expect(headers["authorization"]).to include("SignedHeaders=host;x-amz-content-sha256;x-amz-date")
    expect(headers["authorization"]).to match(/Signature=[a-f0-9]{64}/)
  end
end