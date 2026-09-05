require "rails_helper"

RSpec.describe Storage::BackendFactory do
  it "builds database backend" do
    expect(described_class.build("database")).to be_a(Storage::Backends::DatabaseBackend)
  end

  it "builds local backend" do
    expect(described_class.build("local")).to be_a(Storage::Backends::LocalBackend)
  end

  it "builds s3 backend" do
    old_env = ENV.to_h

    ENV["S3_ENDPOINT"] = "http://localhost:9000"
    ENV["S3_REGION"] = "us-east-1"
    ENV["S3_BUCKET"] = "drive"
    ENV["S3_ACCESS_KEY_ID"] = "access"
    ENV["S3_SECRET_ACCESS_KEY"] = "secret"

    expect(described_class.build("s3")).to be_a(Storage::Backends::S3HttpBackend)
  ensure
    ENV.replace(old_env)
  end

  it "rejects unsupported backend" do
    expect {
      described_class.build("unknown")
    }.to raise_error(ApplicationError) { |error| expect(error.code).to eq("unsupported_storage_backend") }
  end
end