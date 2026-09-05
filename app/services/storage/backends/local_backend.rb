require "digest"
require "fileutils"

module Storage
  module Backends
    class LocalBackend
      def initialize(root_path: ENV.fetch("LOCAL_STORAGE_PATH", Rails.root.join("storage", "blobs").to_s))
        @root_path = Pathname.new(root_path)
      end

      def name
        "local"
      end

      def put(blob:, data:)
        FileUtils.mkdir_p(path_for(blob).dirname)
        File.binwrite(path_for(blob), data)
      end

      def get(blob:)
        path = path_for(blob)

        raise_not_found unless path.file?

        File.binread(path)
      end

      private

      attr_reader :root_path

      def path_for(blob)
        digest = Digest::SHA256.hexdigest(blob.external_id)
        root_path.join(digest[0, 2], digest)
      end

      def raise_not_found
        raise ApplicationErrors.blob_data_not_found(backend: name)
      end
    end
  end
end