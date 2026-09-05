require "rails_helper"

RSpec.describe Storage::S3::ObjectKey do
  it "derives a safe deterministic object key from an external id" do
    key = described_class.call("folder/hello.txt")

    expect(key).to match(%r{\Ablobs/[a-f0-9]{2}/[a-f0-9]{64}\z})
    expect(key).to eq(described_class.call("folder/hello.txt"))
    expect(key).not_to include("folder/hello.txt")
  end
end