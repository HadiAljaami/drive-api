# Manual Test Scenarios

These scenarios can be used to manually verify the Simple Drive API after running the Rails server.

## Start Server

```cmd
set API_AUTH_TOKEN=dev-token
set STORAGE_BACKEND=database
bundle exec rails server
```

## 1. Store Blob

```cmd
curl.exe -i -X POST http://localhost:3000/v1/blobs -H "Authorization: Bearer dev-token" -H "Content-Type: application/json" -d "{\"id\":\"manual/demo.txt\",\"data\":\"SGVsbG8=\"}"
```

Expected result:

```text
HTTP/1.1 201 Created
```

```json
{
  "id": "manual/demo.txt",
  "size": 5,
  "created_at": "..."
}
```

## 2. Retrieve Blob

```cmd
curl.exe -i http://localhost:3000/v1/blobs/manual/demo.txt -H "Authorization: Bearer dev-token"
```

Expected result:

```text
HTTP/1.1 200 OK
```

```json
{
  "id": "manual/demo.txt",
  "data": "SGVsbG8=",
  "size": 5,
  "created_at": "..."
}
```

## 3. Missing Authorization

```cmd
curl.exe -i -X POST http://localhost:3000/v1/blobs -H "Content-Type: application/json" -d "{\"id\":\"manual/no-auth.txt\",\"data\":\"SGVsbG8=\"}"
```

Expected result:

```text
HTTP/1.1 401 Unauthorized
```

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Missing or invalid bearer token."
  }
}
```

## 4. Invalid Base64

```cmd
curl.exe -i -X POST http://localhost:3000/v1/blobs -H "Authorization: Bearer dev-token" -H "Content-Type: application/json" -d "{\"id\":\"manual/invalid.txt\",\"data\":\"not-base64\"}"
```

Expected result:

```text
HTTP/1.1 400 Bad Request
```

```json
{
  "error": {
    "code": "invalid_base64",
    "message": "Data must be a valid Base64-encoded string."
  }
}
```

## 5. Duplicate ID

Run the store command twice with the same `id`.

Expected result on the second request:

```text
HTTP/1.1 409 Conflict
```

```json
{
  "error": {
    "code": "blob_already_exists",
    "message": "Blob already exists."
  }
}
```

## 6. Switch To Local Backend

Stop the server, then start it with:

```cmd
set API_AUTH_TOKEN=dev-token
set STORAGE_BACKEND=local
set LOCAL_STORAGE_PATH=storage/blobs
bundle exec rails server
```

Store and retrieve a new blob using the same commands above with a different `id`.

Expected result:

- New blobs are stored in local filesystem storage.
- Existing blobs still retrieve from the backend saved in their `storage_backend` metadata.

## Automated Verification

```cmd
bundle exec rspec
```

Expected result:

```text
49 examples, 0 failures
```