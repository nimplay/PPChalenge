class ApplicationController < ActionController::API # o Base
   before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    begin
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      @current_user = User.find(decoded.first['sub'])

      # Verificar si el token fue revocado (logout)
      if @current_user.jti != decoded.first['jti']
        raise JWT::DecodeError
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'No autorizado' }, status: :unauthorized
    end
  end
end
