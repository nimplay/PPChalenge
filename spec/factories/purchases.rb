FactoryBot.define do
  factory :purchase do
    association :product
    association :customer
    quantity { rand(1..5) }
    total_price { product.price * quantity }
    created_at { Time.current }
    status { 'completed' }
  end
end
