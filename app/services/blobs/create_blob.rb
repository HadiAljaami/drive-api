require "base64"

module Blobs
  class CreateBlob
    def initialize(storage_backend: Storage::BackendFactory.build)
      @storage_backend = storage_backend
    end

    def call(external_id:, encoded_data:)
      validate_payload!(external_id, encoded_data)

      data = decode_base64!(encoded_data)

      Blob.transaction do
        blob = Blob.create!(
          external_id: external_id,
          size_bytes: data.bytesize,
          storage_backend: storage_backend.name
        )

        storage_backend.put(blob: blob, data: data)

        blob
      end
    rescue ActiveRecord::RecordNotUnique
      raise ApplicationErrors.blob_already_exists
    rescue ActiveRecord::RecordInvalid => error
      raise ApplicationErrors.blob_already_exists if error.record.errors.added?(:external_id, :taken)

      raise
    end

    private

    attr_reader :storage_backend

    def validate_payload!(external_id, encoded_data)
      raise ApplicationErrors.invalid_id unless external_id.is_a?(String)
      raise ApplicationErrors.missing_id if external_id.blank?

      raise ApplicationErrors.invalid_data unless encoded_data.is_a?(String)
      raise ApplicationErrors.missing_data if encoded_data.blank?
    end

    def decode_base64!(encoded_data)
      Base64.strict_decode64(encoded_data)
    rescue ArgumentError
      raise ApplicationErrors.invalid_base64
    end
  end
end