require 'open-uri'
require 'uri'
require 'faker'

puts "Iniciando seed de la aplicación..."

# Safe cleaning (for development only)
if Rails.env.development?
  puts "Limpiando datos existentes..."
  [AuditLog, Purchase, ProductCategory, Category, Product, User, Customer].each do |model|
    model.destroy_all
  end
  ActiveStorage::Attachment.all.each(&:purge)
end

# 1. Crear usuarios administradores y normales
puts "\nCreando usuarios..."
admin_users = [
  {
    email: 'admin1@store.com',
    password: 'Admin123!',
    password_confirmation: 'Admin123!',
    role: 'admin',
    jti: SecureRandom.uuid
  },
  {
    email: 'admin2@store.com',
    password: 'Admin123!',
    password_confirmation: 'Admin123!',
    role: 'admin',
    jti: SecureRandom.uuid
  },
  {
    email: 'manager@store.com',
    password: 'Manager123!',
    password_confirmation: 'Manager123!',
    role: 'manager',
    jti: SecureRandom.uuid
  },
  {
    email: 'user@store.com',
    password: 'User123!',
    password_confirmation: 'User123!',
    role: 'user',
    jti: SecureRandom.uuid
  }
]

admin_users.each do |user_data|
  user = User.create!(
    email: user_data[:email],
    password: user_data[:password],
    password_confirmation: user_data[:password_confirmation],
    role: user_data[:role],
    jti: user_data[:jti]
  )
  puts "-> Usuario creado: #{user.email} (Rol: #{user.role})"
end

# 2. Crear categorías
puts "\nCreando categorías..."
categories = [
  { name: 'Electrónica', description: 'Dispositivos electrónicos y gadgets' },
  { name: 'Ropa', description: 'Prendas de vestir para hombres, mujeres y niños' },
  { name: 'Hogar', description: 'Artículos para el hogar y decoración' },
  { name: 'Deportes', description: 'Artículos deportivos y fitness' },
  { name: 'Juguetes', description: 'Juguetes para niños y coleccionables' }
]

admin_user = User.admins.first

categories.each do |cat_data|
  category = Category.create!(
    name: cat_data[:name],
    description: cat_data[:description],
    creator: admin_user
  )

  AuditLog.create!(
    admin: admin_user,
    action: 'create',
    auditable: category,
    audit_changes: {
      name: category.name,
      description: category.description
    }
  )

  puts "-> Categoría creada: #{category.name}"
end

# 3. Create products with images
puts "\nCreando productos..."
product_data = [
  {
    name: 'Smartphone Premium',
    description: 'Último modelo con cámara de 108MP',
    price: 899.99,
    stock: 50,
    product_type: 'physical',
    categories: ['Electrónica'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/Phone1Mockup.jpg']
  },
  {
    name: 'Laptop Pro',
    description: '16GB RAM, 1TB SSD, Intel i7',
    price: 1299.99,
    stock: 30,
    product_type: 'physical',
    categories: ['Electrónica'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/LaptopMockup.jpg']
  },
  {
    name: 'Auriculares Inalámbricos',
    description: 'Cancelación de ruido, 30h batería',
    price: 199.99,
    stock: 100,
    product_type: 'physical',
    categories: ['Electrónica'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/headphone.jpg']
  },
  {
    name: 'Camisa Formal',
    description: 'Algodón 100%, varios colores',
    price: 49.99,
    stock: 150,
    product_type: 'physical',
    categories: ['Ropa'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/camisa-formal.jpg']
  },
  {
    name: 'Zapatos Deportivos',
    description: 'Amortiguación de aire, tallas 38-45',
    price: 89.99,
    stock: 75,
    product_type: 'physical',
    categories: ['Ropa'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/tenis.webp']
  },
  {
    name: 'Juego de Sábanas',
    description: 'Algodón egipcio, 600 hilos',
    price: 79.99,
    stock: 60,
    product_type: 'physical',
    categories: ['Hogar'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/sabanas.jpg']
  },
  {
    name: 'Lámpara Moderna',
    description: 'LED regulable, diseño escandinavo',
    price: 59.99,
    stock: 40,
    product_type: 'physical',
    categories: ['Hogar'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/lampara.jpg']
  },
  {
    name: 'Pesa Ajustable',
    description: '5-25kg, sistema de discos',
    price: 129.99,
    stock: 30,
    product_type: 'physical',
    categories: ['Deportes'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/pesas.jpg']
  },
  {
    name: 'Set de Construcción',
    description: '250 piezas, para niños 6+',
    price: 39.99,
    stock: 80,
    product_type: 'physical',
    categories: ['Juguetes'],
    image_urls: ['https://technical-challenge-nimplay.s3.us-east-2.amazonaws.com/setconstruccion.jpg']
  }
]

product_data.each do |data|
  Current.user = User.admins.sample

  product = Product.create!(
    name: data[:name],
    description: data[:description],
    price: data[:price],
    stock: data[:stock],
    product_type: data[:product_type],
    creator: Current.user
  )

  data[:categories].each do |cat_name|
    category = Category.find_by!(name: cat_name)
    product.categories << category unless product.categories.include?(category)
  end

  if data[:image_urls].present?
    data[:image_urls].each do |url|
      begin
        downloaded_file = URI.parse(url).open
        product.images.attach(
          io: downloaded_file,
          filename: File.basename(url),
          content_type: downloaded_file.content_type
        )
        puts "   Imagen adjuntada: #{url}"
      rescue OpenURI::HTTPError => e
        puts "   Error al cargar imagen: #{e.message}"
      ensure
        downloaded_file.close if downloaded_file
      end
    end
  end

  puts "-> Producto creado: #{product.name} (ID: #{product.id})"
end

puts "\nCreando clientes y compras de ejemplo..."

date_range = (6.months.ago.to_date..Date.today)

10.times do |i|
  customer = Customer.create!(
    name: Faker::Name.name,
    email: Faker::Internet.unique.email,
    phone: "+569#{rand(10000000..99999999)}",
    address: "#{Faker::Address.street_address}, #{Faker::Address.city}"
  )

  rand(1..3).times do
    product = Product.all.sample
    quantity = rand(1..3)
    random_date = rand(6.months.ago..Time.now)

    purchase = Purchase.create!(
      product: product,
      customer: customer,
      quantity: quantity,
      status: ['completed', 'pending'].sample,
      created_at: random_date,
      updated_at: random_date,
      total_price: product.price * quantity,
    )
  end

  puts "-> Cliente creado: #{customer.name} con #{customer.purchases.count} compras"
end

puts "\nCreando compras adicionales para reportes..."
50.times do
  product = Product.all.sample
  customer = Customer.all.sample
  random_date = rand(date_range)
  quantity = rand(1..3)
  Purchase.create!(
    product: product,
    customer: customer,
    quantity: rand(1..5),
    status: 'completed',
    created_at: random_date,
    updated_at: random_date,
    total_price: product.price * quantity,
  )
end

puts "\nSeed completado exitosamente!"
puts "================================="
puts "Resumen final:"
puts "-> Total categorías: #{Category.count}"
puts "-> Total productos: #{Product.count}"
puts "-> Total imágenes subidas: #{ActiveStorage::Attachment.count}"
puts "-> Total clientes: #{Customer.count}"
puts "-> Total compras: #{Purchase.count}"
puts "-> Rango de fechas de compras: #{Purchase.minimum(:created_at).to_date} al #{Purchase.maximum(:created_at).to_date}"
