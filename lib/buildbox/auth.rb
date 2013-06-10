module Buildbox
  class Auth
    def login(options)
      if Buildbox.configuration.api_key
        error "You have already authentication. To unauthenticate, run `buildbox auth:logout`"
      end

      key = options[:api_key]
      api = Buildbox::API.new(:api_key => key)

      if api.login.success?
        Buildbox.configuration.update :api_key, key
        info "Authentication successful"
      end
    end

    def logout
      if Buildbox.configuration.api_key.nil?
        error "You are currently not logged in. To authenticate, run: `buildbox auth:login`"
      end

      Buildbox.configuration.update :api_key, nil
      info "You have successfuly logged out"
    end

    private

    def info(message)
      Buildbox.logger.info message
    end

    def error(message)
      Buildbox.logger.error message
      exit 1
    end
  end
end
