# Decision Log

This file captures short engineering decisions while the project is built. It is intentionally lightweight so reviewers can scan it quickly.

## 0001 - Treat Blob IDs As Opaque

Decision: Store the caller-provided `id` as `external_id`, and let storage adapters derive a safe internal key when needed.

Reason: The assignment allows IDs to be UUIDs, random strings, names, or paths. If we use the raw ID as a filesystem path or S3 object key, path traversal and encoding edge cases become storage concerns. A derived safe key keeps storage predictable while avoiding an unnecessary metadata column.

Note: `storage_key` can be added later if the key derivation ever needs to change without migrating existing stored objects.

## 0002 - Use Strategy And Factory, Not A Full Domain Framework

Decision: Storage backends implement the same small interface: `name`, `put`, and `get`. A factory selects the backend from configuration.

Reason: The main design challenge is interchangeable storage. Strategy expresses that directly. A factory isolates environment parsing. More layers would make the assignment harder to review without adding much value.

Note: Delete, exists/head, listing, multipart uploads, ACLs, and public URLs are intentionally out of scope because the public API only stores and retrieves blobs.

## 0003 - Separate Metadata From Binary Data

Decision: `blobs` stores metadata only. Raw bytes live in the selected backend. The `database_storage_blobs` table is used only by the database backend.

Reason: This follows the assignment and keeps behavior consistent across local, database, and S3 storage.

## 0004 - Implement FTP Last

Decision: FTP is deferred until the required backends and tests are complete.

Reason: FTP is explicitly bonus scope. A polished core implementation will score better than a wider but thinner submission.

## 0005 - Derive Safe Object Keys For File-Based Storage

Decision: Local and S3 storage derive object keys from `external_id` using a SHA256 digest and split stored files/objects by the first two digest characters, for example `blobs/a1/a1f9...`.

Reason: The assignment allows path-like IDs, but the ID is supposed to be opaque. Using it directly as a filesystem path or S3 key would expose the storage layer to traversal, encoding, length, and platform-specific filename issues. A deterministic digest keeps the key safe without adding a `storage_key` column.

Note: The first two digest characters create 256 logical buckets. This avoids placing every local file in one directory while keeping the layout simple and predictable.

## 0006 - Keep Application Errors Separate From HTTP Rendering

Decision: Services and storage adapters raise `ApplicationError` values through an `ApplicationErrors` catalog. Controllers render those errors through one `ErrorRendering` concern that maps error codes to HTTP statuses.

Reason: Use cases should know what went wrong, not how to serialize an HTTP response. Centralizing error construction avoids repeated messages and keeps API rendering consistent.

## 0007 - Keep S3 As Raw HTTP Behind The Storage Contract

Decision: Implement S3-compatible storage with raw HTTP and AWS Signature Version 4, behind the existing `name`, `put`, and `get` storage contract.

Reason: The assignment explicitly rejects S3 libraries. Keeping S3 behind the same adapter contract lets `CreateBlob` and `RetrieveBlob` remain unchanged while still demonstrating understanding of the S3 protocol.
