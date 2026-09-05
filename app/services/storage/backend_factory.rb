module Storage
  class BackendFactory
    def self.build(name = ENV.fetch("STORAGE_BACKEND", "database"))
      case name.to_s
      when "database"
        Backends::DatabaseBackend.new
      when "local"
        Backends::LocalBackend.new
      when "s3"
        Backends::S3HttpBackend.new
      else
        raise ApplicationErrors.unsupported_storage_backend
      end
    end
  end
end