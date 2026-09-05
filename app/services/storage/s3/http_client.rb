require "net/http"
require "uri"

module Storage
  module S3
    class HttpClient
      def initialize(configuration:, signer: Signer.new(configuration: configuration))
        @configuration = configuration
        @signer = signer
      end

      def put(key:, body:)
        request(:put, key: key, body: body)
      end

      def get(key:)
        request(:get, key: key, body: "").body
      end

      private

      attr_reader :configuration, :signer

      def request(method, key:, body:)
        uri = object_uri(key)
        headers = signer.signed_headers(method: method.to_s.upcase, uri: uri, body: body)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"

        request = request_class(method).new(uri.request_uri)
        headers.each { |name, value| request[name] = value }
        request.body = body if method == :put

        response = http.request(request)
        return response if response.is_a?(Net::HTTPSuccess)

        raise ApplicationErrors.blob_data_not_found(backend: "s3") if response.is_a?(Net::HTTPNotFound)

        raise ApplicationErrors.storage_error(
          message: "S3 #{method.to_s.upcase} request failed with HTTP #{response.code}."
        )
      end

      def object_uri(key)
        uri = configuration.endpoint_uri.dup
        base_path = uri.path.to_s.sub(%r{/+\z}, "")
        object_path = [base_path, escape(configuration.bucket), key.split("/").map { |part| escape(part) }.join("/")].reject(&:blank?).join("/")

        uri.path = "/#{object_path}"
        uri.query = nil
        uri
      end

      def request_class(method)
        method == :put ? Net::HTTP::Put : Net::HTTP::Get
      end

      def escape(value)
        URI.encode_www_form_component(value).gsub("+", "%20")
      end
    end
  end
end