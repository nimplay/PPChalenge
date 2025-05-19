FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }
    price { Faker::Commerce.price(range: 1.0..100.0) }
    stock { Faker::Number.between(from: 1, to: 100) }
    product_type { 'physical' }
    association :creator, factory: :user

    trait :with_category do
      after(:create) do |product|
        create(:product_category, product: product, category: create(:category))
      end
    end

    trait :with_specific_category do
      transient do
        category { create(:category) }
      end

      after(:create) do |product, evaluator|
        create(:product_category, product: product, category: evaluator.category)
      end
    end
  end
end
