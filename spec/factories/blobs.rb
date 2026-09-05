FactoryBot.define do
  factory :blob do
    sequence(:external_id) { |n| "blob-#{n}" }
    size_bytes { 5 }
    storage_backend { "database" }
  end
end