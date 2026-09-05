# Simple Drive

Ruby on Rails API for storing and retrieving binary blobs through one stable interface with configurable storage backends.

This project was built for the Moyasar Hiring: Simple Drive assignment.

## Features

- Rails API-only application.
- PostgreSQL database.
- Bearer token authentication.
- Store blobs with `POST /v1/blobs`.
- Retrieve blobs with `GET /v1/blobs/*id`.
- Supports path-like IDs such as `folder/file.txt`.
- Strict Base64 validation.
- Consistent JSON error responses.
- Pluggable storage backends:
  - Database table
  - Local filesystem
  - S3-compatible storage through raw HTTP
- S3 implementation does not use any S3 SDK or S3 library.
- RSpec coverage for API, services, models, and storage adapters.

## Architecture

The application is structured around a small storage abstraction. Controllers handle HTTP concerns, use-case services handle application workflow, and storage backends handle the physical storage details.

### Request Flow

```text
HTTP Request
  -> V1::BlobsController
  -> Blobs::CreateBlob / Blobs::RetrieveBlob
  -> Storage::BackendFactory
  -> Storage Backend
       - DatabaseBackend
       - LocalBackend
       - S3HttpBackend
```

### Storage Contract

Every storage backend implements the same small contract:

```ruby
name
put(blob:, data:)
get(blob:)
```

This keeps the blob use cases independent from the selected storage backend. Adding a new backend should not require changing the controller or the blob services.

### Project Structure

```text
app/
  controllers/
    application_controller.rb
    concerns/
      bearer_authentication.rb
      error_rendering.rb
    v1/
      blobs_controller.rb

  errors/
    application_error.rb
    application_errors.rb

  models/
    blob.rb
    database_storage_blob.rb

  services/
    blobs/
      create_blob.rb
      retrieve_blob.rb

    storage/
      backend_factory.rb

      backends/
        database_backend.rb
        local_backend.rb
        s3_http_backend.rb

      s3/
        configuration.rb
        http_client.rb
        object_key.rb
        signer.rb
```

### Responsibilities

- `V1::BlobsController`: receives requests and renders JSON responses.
- `Blobs::CreateBlob`: validates input, decodes Base64 data, creates metadata, and stores bytes through the selected backend.
- `Blobs::RetrieveBlob`: loads metadata, reads bytes from the original backend, and returns the API response payload.
- `Storage::BackendFactory`: selects the configured backend.
- `DatabaseBackend`: stores bytes in `database_storage_blobs`.
- `LocalBackend`: stores bytes on disk using safe SHA256-derived paths.
- `S3HttpBackend`: stores bytes in S3-compatible storage using raw HTTP and AWS Signature Version 4.
- `ApplicationErrors`: centralizes application error codes and messages.
- `ErrorRendering`: maps application errors to HTTP statuses and a consistent JSON error format.

## Design Decisions

The public blob `id` is treated as opaque. It may be a UUID, random string, name, or path-like value. Storage adapters do not use it directly as a file path or S3 object key.

For file-based storage, the app derives a safe SHA256-based key:

```text
blobs/44/44543f2cdf9e47...
```

This avoids path traversal, encoding issues, platform-specific filename issues, and very large single directories.

S3 storage is implemented using Ruby HTTP primitives and AWS Signature Version 4. This follows the assignment requirement to avoid S3 libraries while keeping protocol details isolated from the blob use cases.

More details are documented in:

- `docs/project-spec.md`
- `docs/decision-log.md`
- `docs/manual-test-scenarios.md`

## Requirements

- Ruby
- Rails
- PostgreSQL
- Bundler

## Setup

Install dependencies:

```bash
bundle install
```

Create and migrate the database:

```bash
bundle exec rails db:create
bundle exec rails db:migrate
```

Prepare the test database:

```bash
bundle exec rails db:test:prepare
```

## Configuration

Create local environment variables based on `.env.example`.

For Windows `cmd`:

```cmd
set API_AUTH_TOKEN=dev-token
set STORAGE_BACKEND=database
```

For PowerShell:

```powershell
$env:API_AUTH_TOKEN="dev-token"
$env:STORAGE_BACKEND="database"
```

Supported storage backends:

```text
database
local
s3
```

### Database Backend

```text
STORAGE_BACKEND=database
```

Stores raw blob bytes in the `database_storage_blobs` table.

### Local Backend

```text
STORAGE_BACKEND=local
LOCAL_STORAGE_PATH=storage/blobs
```

Stores raw blob bytes on the local filesystem using safe SHA256-derived paths.

### S3 Backend

```text
STORAGE_BACKEND=s3
S3_ENDPOINT=http://localhost:9000
S3_REGION=us-east-1
S3_BUCKET=drive
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=minioadmin
```

The S3 backend uses raw HTTP requests with AWS Signature Version 4.

## Run The Server

```bash
bundle exec rails server
```

The API will be available at:

```text
http://localhost:3000
```

## API

All requests require:

```http
Authorization: Bearer <token>
```

### Store Blob

```http
POST /v1/blobs
Content-Type: application/json
Authorization: Bearer dev-token
```

Request:

```json
{
  "id": "folder/hello.txt",
  "data": "SGVsbG8="
}
```

Response:

```json
{
  "id": "folder/hello.txt",
  "size": 5,
  "created_at": "2026-09-05T14:31:03Z"
}
```

### Retrieve Blob

```http
GET /v1/blobs/folder/hello.txt
Authorization: Bearer dev-token
```

Response:

```json
{
  "id": "folder/hello.txt",
  "data": "SGVsbG8=",
  "size": 5,
  "created_at": "2026-09-05T14:31:03Z"
}
```

## Curl Examples

Create a blob on Windows `cmd`:

```cmd
curl.exe -i -X POST http://localhost:3000/v1/blobs -H "Authorization: Bearer dev-token" -H "Content-Type: application/json" -d "{\"id\":\"api/demo.txt\",\"data\":\"SGVsbG8=\"}"
```

Retrieve a blob on Windows `cmd`:

```cmd
curl.exe -i http://localhost:3000/v1/blobs/api/demo.txt -H "Authorization: Bearer dev-token"
```

## Error Format

All API errors use the same shape:

```json
{
  "error": {
    "code": "invalid_base64",
    "message": "Data must be a valid Base64-encoded string."
  }
}
```

Common error codes:

```text
invalid_json
invalid_id
missing_id
invalid_data
missing_data
invalid_base64
unauthorized
blob_not_found
blob_already_exists
unsupported_storage_backend
blob_data_not_found
storage_error
```

## Testing

Run all tests:

```bash
bundle exec rspec
```

Current coverage includes:

- Model validations.
- Bearer authentication.
- Create blob API.
- Retrieve blob API.
- Path-like blob IDs.
- Invalid Base64.
- Duplicate IDs.
- Missing blobs.
- Backend factory.
- Database backend.
- Local backend.
- S3 configuration.
- S3 object key derivation.
- S3 Signature V4 headers.
- S3 HTTP PUT/GET behavior using WebMock.
