require "digest"

module Storage
  module S3
    class ObjectKey
      def self.call(external_id)
        digest = Digest::SHA256.hexdigest(external_id)
        "blobs/#{digest[0, 2]}/#{digest}"
      end
    end
  end
end