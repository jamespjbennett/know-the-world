module ApiCredentials
  class << self
    attr_writer :credentials_source

    def anthropic_api_key
      fetch("ANTHROPIC_API_KEY", :anthropic)
    end

    def tavily_api_key
      fetch("TAVILY_API_KEY", :tavily)
    end

    def from_credentials(provider)
      credentials_source.dig(provider, :api_key).presence
    end

    def credentials_source
      @credentials_source || Rails.application.credentials
    end

    def reset_credentials_source!
      @credentials_source = nil
    end

    private

    def fetch(env_key, provider)
      ENV[env_key].presence || from_credentials(provider) || missing!(env_key, provider)
    end

    def missing!(env_key, provider)
      fail KeyError,
        "Missing #{provider} API key. Set #{env_key} or add credentials.#{provider}.api_key " \
        "via `bin/rails credentials:edit`."
    end
  end
end
