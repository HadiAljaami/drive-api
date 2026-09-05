Rails.application.routes.draw do
  namespace :v1 do
    post "blobs", to: "blobs#create"
    get "blobs/*id", to: "blobs#show", format: false
  end
end