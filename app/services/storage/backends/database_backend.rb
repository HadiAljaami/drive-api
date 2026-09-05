module Storage
  module Backends
    class DatabaseBackend
      def name
        "database"
      end

      def put(blob:, data:)
        blob.create_database_storage_blob!(data: data)
      end

      def get(blob:)
        blob.database_storage_blob&.data || raise_not_found
      end

      private

      def raise_not_found
        raise ApplicationErrors.blob_data_not_found(backend: name)
      end
    end
  end
end