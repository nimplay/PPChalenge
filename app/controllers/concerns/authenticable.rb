module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
    attr_reader :current_user
  end

  private

  def authenticate_request
    auth_header = request.headers['Authorization']
    token = auth_header&.split(' ')&.last

    unless token
      return render_unauthorized('Token missing')
    end

    begin
      decoded_token = decode_jwt(token)
      @current_user = find_user(decoded_token)

      if token_revoked?(decoded_token, @current_user)
        return render_unauthorized('Token revoked')
      end
    rescue JWT::DecodeError => e
      return render_unauthorized('Invalid token')
    rescue ActiveRecord::RecordNotFound => e
      return render_unauthorized('User not found')
    end
  end

  def decode_jwt(token)
    JWT.decode(
      token,
      Rails.application.credentials.secret_key_base,
      true,
      { algorithm: 'HS256' }
    ).first
  end

  def find_user(decoded_token)
    User.find(decoded_token['sub'])
  end

  def token_revoked?(decoded_token, user)
    user.jti != decoded_token['jti']
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
