module ErrorRendering
  extend ActiveSupport::Concern

  ERROR_STATUSES = {
    "invalid_json" => :bad_request,
    "invalid_id" => :bad_request,
    "missing_id" => :bad_request,
    "invalid_data" => :bad_request,
    "missing_data" => :bad_request,
    "invalid_base64" => :bad_request,
    "unauthorized" => :unauthorized,
    "blob_not_found" => :not_found,
    "blob_already_exists" => :conflict,
    "unsupported_storage_backend" => :internal_server_error,
    "blob_data_not_found" => :internal_server_error,
    "storage_error" => :internal_server_error
  }.freeze

  included do
    rescue_from ApplicationError, with: :render_application_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_invalid_json
  end

  private

  def render_application_error(error)
    render json: {
      error: {
        code: error.code,
        message: error.message
      }
    }, status: ERROR_STATUSES.fetch(error.code, :internal_server_error)
  end

  def render_not_found
    render_application_error(ApplicationErrors.blob_not_found)
  end

  def render_record_invalid(error)
    render json: {
      error: {
        code: "validation_failed",
        message: error.record.errors.full_messages.to_sentence
      }
    }, status: :unprocessable_entity
  end

  def render_invalid_json
    render_application_error(
      ApplicationError.new(
        code: "invalid_json",
        message: "Request body must be valid JSON."
      )
    )
  end
end