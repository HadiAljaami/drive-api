module ApplicationErrors
  module_function

  def invalid_id
    ApplicationError.new(code: "invalid_id", message: "ID must be a string.")
  end

  def missing_id
    ApplicationError.new(code: "missing_id", message: "ID is required.")
  end

  def invalid_data
    ApplicationError.new(code: "invalid_data", message: "Data must be a Base64-encoded string.")
  end

  def missing_data
    ApplicationError.new(code: "missing_data", message: "Data is required.")
  end

  def invalid_base64
    ApplicationError.new(
      code: "invalid_base64",
      message: "Data must be a valid Base64-encoded string."
    )
  end

  def unauthorized
    ApplicationError.new(
      code: "unauthorized",
      message: "Missing or invalid bearer token."
    )
  end

  def blob_not_found
    ApplicationError.new(code: "blob_not_found", message: "Blob was not found.")
  end

  def blob_already_exists
    ApplicationError.new(code: "blob_already_exists", message: "Blob already exists.")
  end

  def unsupported_storage_backend
    ApplicationError.new(
      code: "unsupported_storage_backend",
      message: "Unsupported storage backend."
    )
  end

  def blob_data_not_found(backend:)
    ApplicationError.new(
      code: "blob_data_not_found",
      message: "Blob data was not found in #{backend} storage."
    )
  end
end