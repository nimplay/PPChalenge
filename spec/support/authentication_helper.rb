module AuthenticationHelper
  def generate_jwt_for(user)
    payload = {
      sub: user.id, # Asegúrate que coincida con lo que espera Authenticable
      exp: 24.hours.from_now.to_i,
      jti: user.jti || SecureRandom.uuid,
      role: user.role
    }
    secret = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    JWT.encode(payload, secret, 'HS256')
  end
  def auth_headers_for(user)
    token = generate_jwt_for(user)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
