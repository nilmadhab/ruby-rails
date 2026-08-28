FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence(word_count: 5) }
    body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    association :user
    association :category
  end
end
