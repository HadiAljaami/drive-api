# app/services/storage/backend_factory.rb
module Storage
  class BackendFactory
    def self.build(name = ENV.fetch("STORAGE_BACKEND", "database"))
      case name.to_s
      when "database"
        Backends::DatabaseBackend.new
      when "local"
        Backends::LocalBackend.new
      else
        raise ApplicationErrors.unsupported_storage_backend
      end
    end
  end
end