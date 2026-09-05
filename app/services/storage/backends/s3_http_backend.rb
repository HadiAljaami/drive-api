# app/services/storage/backends/s3_http_backend.rb
module Storage
  module Backends
    class S3HttpBackend
      def initialize(configuration: Storage::S3::Configuration.from_env, http_client: nil)
        @configuration = configuration
        @http_client = http_client || Storage::S3::HttpClient.new(configuration: configuration)
      end

      def name
        "s3"
      end

      def put(blob:, data:)
        http_client.put(key: object_key(blob), body: data)
      end

      def get(blob:)
        http_client.get(key: object_key(blob))
      end

      private

      attr_reader :configuration, :http_client

      def object_key(blob)
        Storage::S3::ObjectKey.call(blob.external_id)
      end
    end
  end
end