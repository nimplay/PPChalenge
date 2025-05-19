FactoryBot.define do
  factory :customer do
    name { "Cliente Ejemplo" }
    email { "cliente@example.com" }
    phone { "+1234567890" }
    address { "Calle Falsa 123" }
  end
end
