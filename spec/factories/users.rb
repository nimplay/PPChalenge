FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    role { 'admin' }
    jti { SecureRandom.uuid }

    trait :admin do
      role { 'admin' }
    end
  end
end

