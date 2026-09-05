# app/errors/api_error.rb
class ApiError < StandardError
  attr_reader :code, :status

  def initialize(code:, message:, status:)
    super(message)
    @code = code
    @status = status
  end
end