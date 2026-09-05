class ApplicationController < ActionController::API
  include ErrorRendering
  include BearerAuthentication
end