require "base64"

module Blobs
  class RetrieveBlob
    def initialize(storage_backend_factory: Storage::BackendFactory)
      @storage_backend_factory = storage_backend_factory
    end

    def call(external_id:)
      raise missing_id if external_id.blank?

      blob = Blob.find_by!(external_id: external_id)
      data = storage_backend_factory.build(blob.storage_backend).get(blob: blob)

      {
        id: blob.external_id,
        data: Base64.strict_encode64(data),
        size: blob.size_bytes,
        created_at: blob.created_at.utc.iso8601
      }
    end

    private

    attr_reader :storage_backend_factory

    def missing_id
      ApiError.new(
        code: "missing_id",
        message: "ID is required.",
        status: :bad_request
      )
    end
  end
end