module ErrorRendering
  extend ActiveSupport::Concern

  included do
    rescue_from ApiError, with: :render_api_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_invalid_json
  end

  private

  def render_api_error(error)
    render json: {
      error: {
        code: error.code,
        message: error.message
      }
    }, status: error.status
  end

  def render_not_found
    render json: {
      error: {
        code: "blob_not_found",
        message: "Blob was not found."
      }
    }, status: :not_found
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
    render json: {
      error: {
        code: "invalid_json",
        message: "Request body must be valid JSON."
      }
    }, status: :bad_request
  end
end