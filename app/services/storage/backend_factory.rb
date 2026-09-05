module Storage
  class BackendFactory
    def self.build(name = ENV.fetch("STORAGE_BACKEND", "database"))
      case name.to_s
      when "database"
        Backends::DatabaseBackend.new
      when "local"
        Backends::LocalBackend.new
      else
        raise ApiError.new(
          code: "unsupported_storage_backend",
          message: "Unsupported storage backend.",
          status: :internal_server_error
        )
      end
    end
  end
end