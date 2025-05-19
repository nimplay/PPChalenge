if Rails.env.production?
  Rswag::Ui.configure do |c|
    c.basic_auth_enabled = true
    c.basic_auth_credentials = {
      username: ENV.fetch("SWAGGER_USERNAME"),
      password: ENV.fetch("SWAGGER_PASSWORD")
    }
  end
end
