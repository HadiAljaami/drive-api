require "rails_helper"

RSpec.describe Storage::S3::HttpClient do
  let(:configuration) do
    Storage::S3::Configuration.new(
      endpoint: "http://s3.test:9000",
      region: "us-east-1",
      bucket: "drive",
      access_key_id: "test-access",
      secret_access_key: "test-secret"
    )
  end

  let(:client) { described_class.new(configuration: configuration) }

  it "puts an object using a signed HTTP request" do
    stub = stub_request(:put, "http://s3.test:9000/drive/blobs/ab/key")
      .with(
        body: "hello",
        headers: {
          "Authorization" => /AWS4-HMAC-SHA256/,
          "X-Amz-Date" => /\d{8}T\d{6}Z/,
          "X-Amz-Content-Sha256" => Digest::SHA256.hexdigest("hello")
        }
      )
      .to_return(status: 200, body: "")

    client.put(key: "blobs/ab/key", body: "hello")

    expect(stub).to have_been_requested
  end

  it "gets an object using a signed HTTP request" do
    stub = stub_request(:get, "http://s3.test:9000/drive/blobs/ab/key")
      .with(headers: { "Authorization" => /AWS4-HMAC-SHA256/ })
      .to_return(status: 200, body: "hello")

    result = client.get(key: "blobs/ab/key")

    expect(result).to eq("hello")
    expect(stub).to have_been_requested
  end

  it "raises blob_data_not_found on 404" do
    stub_request(:get, "http://s3.test:9000/drive/blobs/ab/missing")
      .to_return(status: 404, body: "")

    expect {
      client.get(key: "blobs/ab/missing")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("blob_data_not_found") }
  end

  it "raises storage_error on unexpected response" do
    stub_request(:put, "http://s3.test:9000/drive/blobs/ab/key")
      .to_return(status: 500, body: "failed")

    expect {
      client.put(key: "blobs/ab/key", body: "hello")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("storage_error") }
  end
end