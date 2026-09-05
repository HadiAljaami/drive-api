require "uri"

module Storage
  module S3
    class Configuration
      attr_reader :endpoint, :region, :bucket, :access_key_id, :secret_access_key

      def self.from_env
        new(
          endpoint: ENV["S3_ENDPOINT"],
          region: ENV["S3_REGION"],
          bucket: ENV["S3_BUCKET"],
          access_key_id: ENV["S3_ACCESS_KEY_ID"],
          secret_access_key: ENV["S3_SECRET_ACCESS_KEY"]
        )
      end

      def initialize(endpoint:, region:, bucket:, access_key_id:, secret_access_key:)
        @endpoint = endpoint.to_s
        @region = region.to_s
        @bucket = bucket.to_s
        @access_key_id = access_key_id.to_s
        @secret_access_key = secret_access_key.to_s

        validate!
      end

      def endpoint_uri
        @endpoint_uri ||= URI.parse(endpoint)
      end

      private

      def validate!
        missing = {
          "S3_ENDPOINT" => endpoint,
          "S3_REGION" => region,
          "S3_BUCKET" => bucket,
          "S3_ACCESS_KEY_ID" => access_key_id,
          "S3_SECRET_ACCESS_KEY" => secret_access_key
        }.select { |_key, value| value.blank? }.keys

        raise ApplicationErrors.storage_error(message: "Missing S3 configuration: #{missing.join(', ')}.") if missing.any?

        raise ApplicationErrors.storage_error(message: "S3_ENDPOINT must be an HTTP or HTTPS URL.") unless endpoint_uri.is_a?(URI::HTTP)
      rescue URI::InvalidURIError
        raise ApplicationErrors.storage_error(message: "S3_ENDPOINT must be a valid URL.")
      end
    end
  end
end