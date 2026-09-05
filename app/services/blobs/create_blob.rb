require "base64"

module Blobs
  class CreateBlob
    def initialize(storage_backend: Storage::BackendFactory.build)
      @storage_backend = storage_backend
    end

    def call(external_id:, encoded_data:)
      validate_presence!(external_id, encoded_data)

      data = decode_base64!(encoded_data)

      Blob.transaction do
        blob = Blob.create!(
          external_id: external_id,
          size_bytes: data.bytesize,
          storage_backend: storage_backend_name
        )

        storage_backend.put(blob: blob, data: data)

        blob
      end
    rescue ActiveRecord::RecordNotUnique
      raise already_exists
    rescue ActiveRecord::RecordInvalid => error
      raise already_exists if error.record.errors.added?(:external_id, :taken)

      raise
    end

    private

    attr_reader :storage_backend

    def validate_presence!(external_id, encoded_data)
      raise missing_id if external_id.blank?
      raise missing_data if encoded_data.blank?
    end

    def decode_base64!(encoded_data)
      Base64.strict_decode64(encoded_data)
    rescue ArgumentError
      raise ApiError.new(
        code: "invalid_base64",
        message: "Data must be a valid Base64-encoded string.",
        status: :bad_request
      )
    end

    def storage_backend_name
      ENV.fetch("STORAGE_BACKEND", "database")
    end

    def missing_id
      ApiError.new(
        code: "missing_id",
        message: "ID is required.",
        status: :bad_request
      )
    end

    def missing_data
      ApiError.new(
        code: "missing_data",
        message: "Data is required.",
        status: :bad_request
      )
    end

    def already_exists
      ApiError.new(
        code: "blob_already_exists",
        message: "Blob already exists.",
        status: :conflict
      )
    end
  end
end