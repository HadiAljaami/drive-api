# app/controllers/concerns/bearer_authentication.rb
module BearerAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
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