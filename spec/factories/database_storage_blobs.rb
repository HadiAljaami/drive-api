FactoryBot.define do
  factory :database_storage_blob do
    blob
    data { "hello" }
  end
end