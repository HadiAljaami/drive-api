# app/services/storage/backends/database_backend.rb
module Storage
  module Backends
    class DatabaseBackend
      def put(blob:, data:)
        blob.create_database_storage_blob!(data: data)
      end

      def get(blob:)
        blob.database_storage_blob&.data || raise_not_found
      end

      private

      def raise_not_found
        raise ApiError.new(
          code: "blob_data_not_found",
          message: "Blob data was not found in database storage.",
          status: :internal_server_error
        )
      end
    end
  end
end