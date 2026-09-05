# Provides Bearer token authentication for API requests.
# Authentication is applied before any controller action is executed.
module BearerAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
    # The token is kept outside the source code and provided
    # through an environment variable.
    expected_token = ENV.fetch("API_AUTH_TOKEN", "dev-token")
    provided_token = request.authorization.to_s.match(/\ABearer (.+)\z/)&.[](1)

    return if provided_token.present? && ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)

    raise ApiError.new(
      code: "unauthorized",
      message: "Missing or invalid bearer token.",
      status: :unauthorized
    )
  end
end