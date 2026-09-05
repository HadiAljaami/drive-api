# Represents an expected API-level error with a stable error code
# and HTTP status that can be rendered consistently by controllers.
class ApiError < StandardError
  attr_reader :code, :status

  def initialize(code:, message:, status:)
    super(message)
    @code = code
    @status = status
  end
end