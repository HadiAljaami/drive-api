# Project Spec

## Goal

Build a production-ready Ruby on Rails API that stores and retrieves blobs by a caller-provided identifier. The API must expose one stable contract while supporting multiple configurable storage backends.

## Source Of Requirements

The hiring assignment PDF is treated as the product brief. Its contents define the application requirements and project constraints.

## In Scope

- Rails API-only application.
- PostgreSQL as the application database.
- Bearer token authentication on all API requests.
- Store a blob through `POST /v1/blobs`.
- Retrieve a blob through `GET /v1/blobs/<id>`.
- Validate that incoming `data` is strict Base64.
- Return blob metadata: `id`, Base64 `data`, byte `size`, and UTC `created_at`.
- Track blob metadata in a `blobs` table.
- Store binary data outside `blobs`, depending on the selected backend.
- Storage backends:
  - Local filesystem.
  - Database table.
  - S3-compatible storage using raw HTTP only.
- Automated tests for request behavior and storage contracts.

## Out Of Scope

- User registration, teams, roles, or OAuth.
- Listing, searching, updating, or deleting blobs.
- Multipart uploads.
- Public file URLs.
- Encryption-at-rest beyond what the selected infrastructure provides.
- FTP in the first implementation. It can be added as a bonus adapter after the core scope is complete.

## Constraints

- Do not use any S3 SDK or S3-specific library.
- The external `id` can be any valid string, including path-like values.
- The external `id` must be treated as an opaque identifier, not as a filesystem path.
- The application must reject invalid Base64 before storage.
- Stored metadata and stored binary data must be separated.
- Keep architecture clean without unnecessary layers.

## Architecture

The app will use a small service boundary around blob storage:

- Controller: HTTP concerns only.
- Request validator: authentication, required fields, strict Base64 validation.
- Use case service: create/retrieve blob workflow and transaction boundary.
- Storage adapter interface: `name`, `put`, and `get`.
- Storage adapter factory: selects the adapter from `STORAGE_BACKEND`.
- ActiveRecord models: persistence for metadata and database-backed binary data.
- Application errors: use cases and adapters raise application-level errors; the API layer maps those errors to HTTP statuses and JSON responses.

Proposed shape:

```text
app/
├── controllers/
│   ├── application_controller.rb
│   ├── concerns/
│   │   ├── bearer_authentication.rb
│   │   └── error_rendering.rb
│   └── v1/
│       └── blobs_controller.rb
├── errors/
│   ├── application_error.rb
│   └── application_errors.rb
├── models/
│   ├── blob.rb
│   └── database_storage_blob.rb
└── services/
    ├── blobs/
    │   ├── create_blob.rb
    │   └── retrieve_blob.rb
    └── storage/
        ├── backend_factory.rb
        ├── backends/
        │   ├── database_backend.rb
        │   ├── local_backend.rb
        │   └── s3_http_backend.rb
        └── s3/
            ├── configuration.rb
            ├── http_client.rb
            ├── object_key.rb
            └── signer.rb
```

This uses Strategy for storage backends and a small Factory for backend selection. That is enough abstraction for the assignment without turning the app into a framework.

### S3 HTTP Adapter Design

The S3-compatible backend is implemented as raw HTTP behind the same storage contract used by local and database storage.

Components:

- `Storage::Backends::S3HttpBackend`: implements `name`, `put`, and `get`.
- `Storage::S3::Configuration`: reads and validates S3 environment variables.
- `Storage::S3::ObjectKey`: derives a safe object key from the opaque external blob ID.
- `Storage::S3::Signer`: creates AWS Signature Version 4 authorization headers.
- `Storage::S3::HttpClient`: sends signed `PUT` and `GET` requests using Ruby HTTP primitives.

The S3 adapter does not use any S3 SDK. This keeps the implementation aligned with the assignment while isolating protocol details from the blob use cases.

## Database

### `blobs`

Tracks metadata for every stored blob.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | bigint | Internal primary key. |
| `external_id` | string | Caller-provided identifier. Unique. |
| `size_bytes` | integer | Decoded binary size. |
| `storage_backend` | string | Backend used when the blob was stored. |
| `created_at` | datetime | UTC timestamp. |

Storage adapters derive their own safe internal key from `external_id` when needed, for example by hashing it. This keeps the public ID opaque without adding an extra metadata column.

### `database_storage_blobs`

Used only when `STORAGE_BACKEND=database`.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | bigint | Internal primary key. |
| `blob_id` | bigint | Foreign key to `blobs`. Unique. |
| `data` | binary | Raw decoded bytes. |
| `created_at` | datetime | Rails timestamp. |

## API Contract

### Authentication

Every request must include:

```http
Authorization: Bearer <token>
```

For this assignment, a single server-side token is enough:

```text
API_AUTH_TOKEN=<secure-token>
```

### Store Blob

```http
POST /v1/blobs
Content-Type: application/json
Authorization: Bearer <token>
```

```json
{
  "id": "any_valid_string_or_identifier",
  "data": "SGVsbG8gU2ltcGxlIFN0b3JhZ2UgV29ybGQh"
}
```

Success:

```http
201 Created
```

```json
{
  "id": "any_valid_string_or_identifier",
  "size": 27,
  "created_at": "2023-01-22T21:37:55Z"
}
```

### Retrieve Blob

The route should support path-like IDs:

```http
GET /v1/blobs/*id
Authorization: Bearer <token>
```

Success:

```http
200 OK
```

```json
{
  "id": "any_valid_string_or_identifier",
  "data": "SGVsbG8gU2ltcGxlIFN0b3JhZ2UgV29ybGQh",
  "size": 27,
  "created_at": "2023-01-22T21:37:55Z"
}
```

## Error Format

All errors return a consistent shape:

```json
{
  "error": {
    "code": "invalid_base64",
    "message": "Data must be a valid Base64-encoded string."
  }
}
```

Planned error cases:

| Status | Code | Meaning |
| --- | --- | --- |
| `400` | `invalid_json` | Request body is not valid JSON. |
| `400` | `invalid_id` | `id` must be a string. |
| `400` | `missing_id` | `id` is missing or blank. |
| `400` | `invalid_data` | `data` must be a string. |
| `400` | `missing_data` | `data` is missing or blank. |
| `400` | `invalid_base64` | `data` cannot be strictly decoded. |
| `401` | `unauthorized` | Missing or invalid bearer token. |
| `404` | `blob_not_found` | No blob exists for the requested ID. |
| `409` | `blob_already_exists` | The supplied ID has already been stored. |
| `500` | `unsupported_storage_backend` | `STORAGE_BACKEND` is not supported. |
| `500` | `blob_data_not_found` | Metadata exists, but backend data is missing. |
| `500` | `storage_error` | Backend failed unexpectedly. |

## Configuration

```text
DATABASE_URL=postgres://...
API_AUTH_TOKEN=...
STORAGE_BACKEND=local|database|s3
LOCAL_STORAGE_PATH=storage/blobs
S3_ENDPOINT=https://...
S3_REGION=...
S3_BUCKET=...
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
```

## Testing

The automated test suite covers:

- Request specs:
  - Authentication required.
  - Store valid blob.
  - Reject invalid Base64.
  - Reject duplicate ID.
  - Retrieve existing blob.
  - Return 404 for missing blob.
  - Support IDs containing slashes.
- Unit specs:
  - Model validations.
  - Blob create and retrieve use cases.
  - Backend factory selection.
  - Database storage backend.
  - Local filesystem storage backend.
  - S3 configuration validation.
  - S3 object key derivation.
  - S3 Signature Version 4 headers.
  - S3 HTTP PUT and GET behavior through WebMock.

Manual API scenarios are documented in `docs/manual-test-scenarios.md`.

