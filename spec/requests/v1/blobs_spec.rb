require "rails_helper"

RSpec.describe "V1::Blobs", type: :request do
  around do |example|
    old_token = ENV["API_AUTH_TOKEN"]
    old_backend = ENV["STORAGE_BACKEND"]
    ENV["API_AUTH_TOKEN"] = "test-token"
    ENV["STORAGE_BACKEND"] = "database"
    example.run
  ensure
    ENV["API_AUTH_TOKEN"] = old_token
    ENV["STORAGE_BACKEND"] = old_backend
  end

  def json
    JSON.parse(response.body)
  end

  def auth_headers
    {
      "Authorization" => "Bearer test-token",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  it "stores a blob" do
    post "/v1/blobs",
      params: { id: "hello.txt", data: Base64.strict_encode64("hello") }.to_json,
      headers: auth_headers

    expect(response).to have_http_status(:created)
    expect(json).to include(
      "id" => "hello.txt",
      "size" => 5
    )
    expect(json["created_at"]).to be_present
  end

  it "retrieves a blob by id" do
    post "/v1/blobs",
      params: { id: "folder/hello.txt", data: Base64.strict_encode64("hello") }.to_json,
      headers: auth_headers

    get "/v1/blobs/folder/hello.txt", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(json).to include(
      "id" => "folder/hello.txt",
      "data" => "aGVsbG8=",
      "size" => 5
    )
    expect(json["created_at"]).to be_present
  end

  it "rejects missing authorization" do
    post "/v1/blobs",
      params: { id: "hello.txt", data: "aGVsbG8=" }.to_json,
      headers: auth_headers.except("Authorization")

    expect(response).to have_http_status(:unauthorized)
    expect(json).to eq(
      "error" => {
        "code" => "unauthorized",
        "message" => "Missing or invalid bearer token."
      }
    )
  end

  it "rejects invalid authorization" do
    post "/v1/blobs",
      params: { id: "hello.txt", data: "aGVsbG8=" }.to_json,
      headers: auth_headers.merge("Authorization" => "Bearer wrong")

    expect(response).to have_http_status(:unauthorized)
    expect(json.dig("error", "code")).to eq("unauthorized")
  end

  it "rejects missing id" do
    post "/v1/blobs",
      params: { data: "aGVsbG8=" }.to_json,
      headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(json.dig("error", "code")).to eq("invalid_id")
  end

  it "rejects missing data" do
    post "/v1/blobs",
      params: { id: "hello.txt" }.to_json,
      headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(json.dig("error", "code")).to eq("invalid_data")
  end

  it "rejects invalid base64" do
    post "/v1/blobs",
      params: { id: "hello.txt", data: "not-base64" }.to_json,
      headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(json.dig("error", "code")).to eq("invalid_base64")
  end

  it "rejects duplicate ids" do
    payload = { id: "same-id", data: "aGVsbG8=" }.to_json

    post "/v1/blobs", params: payload, headers: auth_headers
    post "/v1/blobs", params: payload, headers: auth_headers

    expect(response).to have_http_status(:conflict)
    expect(json.dig("error", "code")).to eq("blob_already_exists")
  end

  it "returns not found for missing blobs" do
    get "/v1/blobs/missing.txt", headers: auth_headers

    expect(response).to have_http_status(:not_found)
    expect(json.dig("error", "code")).to eq("blob_not_found")
  end
end