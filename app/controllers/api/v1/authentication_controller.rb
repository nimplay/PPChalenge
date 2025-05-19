module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_request, only: [ :login ]

      def login
        user = User.find_by(email: params[:email].downcase.strip)

        if user&.authenticate(params[:password])
          token = user.generate_jwt
          render json: {
            token: token,
            user: {
              id: user.id,
              email: user.email,
              role: user.role
            }
          }, status: :ok
        else
          render json: { error: "Email o contraseña inválidos" }, status: :unauthorized
        end
      end

      def logout
        current_user.update(jti: SecureRandom.uuid)
        head :no_content
      end

      private

      def login_params
        params.require(:email)
        params.require(:password)
        params.permit(:email, :password)
      end
    end
  end
end
