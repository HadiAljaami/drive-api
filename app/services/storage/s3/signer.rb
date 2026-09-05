require "digest"
require "openssl"
require "time"

module Storage
  module S3
    class Signer
      ALGORITHM = "AWS4-HMAC-SHA256"
      SERVICE = "s3"

      def initialize(configuration:)
        @configuration = configuration
      end

      def signed_headers(method:, uri:, body:, time: Time.now.utc, headers: {})
        payload_hash = Digest::SHA256.hexdigest(body.to_s)
        amz_date = time.strftime("%Y%m%dT%H%M%SZ")
        date_stamp = time.strftime("%Y%m%d")

        signing_headers = normalize_headers(headers).merge(
          "host" => host_header(uri),
          "x-amz-content-sha256" => payload_hash,
          "x-amz-date" => amz_date
        )

        signed_header_names = signing_headers.keys.sort
        signed_headers_value = signed_header_names.join(";")
        credential_scope = "#{date_stamp}/#{configuration.region}/#{SERVICE}/aws4_request"

        canonical_request = [
          method.upcase,
          uri.path,
          uri.query.to_s,
          canonical_headers(signing_headers, signed_header_names),
          signed_headers_value,
          payload_hash
        ].join("\n")

        string_to_sign = [
          ALGORITHM,
          amz_date,
          credential_scope,
          Digest::SHA256.hexdigest(canonical_request)
        ].join("\n")

        signature = OpenSSL::HMAC.hexdigest("SHA256", signing_key(date_stamp), string_to_sign)

        signing_headers.merge(
          "authorization" => "#{ALGORITHM} Credential=#{configuration.access_key_id}/#{credential_scope}, SignedHeaders=#{signed_headers_value}, Signature=#{signature}"
        )
      end

      private

      attr_reader :configuration

      def normalize_headers(headers)
        headers.transform_keys { |key| key.to_s.downcase }
      end

      def canonical_headers(headers, names)
        names.map { |name| "#{name}:#{headers.fetch(name).to_s.strip.gsub(/\s+/, ' ')}\n" }.join
      end

      def host_header(uri)
        default_port = uri.scheme == "https" ? 443 : 80
        uri.port == default_port ? uri.host : "#{uri.host}:#{uri.port}"
      end

      def signing_key(date_stamp)
        date_key = hmac("AWS4#{configuration.secret_access_key}", date_stamp)
        region_key = hmac(date_key, configuration.region)
        service_key = hmac(region_key, SERVICE)
        hmac(service_key, "aws4_request")
      end

      def hmac(key, value)
        OpenSSL::HMAC.digest("SHA256", key, value)
      end
    end
  end
end