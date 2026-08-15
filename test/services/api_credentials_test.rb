require "test_helper"

class ApiCredentialsTest < ActiveSupport::TestCase
  setup do
    @original_anthropic = ENV["ANTHROPIC_API_KEY"]
    @original_tavily = ENV["TAVILY_API_KEY"]
  end

  teardown do
    restore_env("ANTHROPIC_API_KEY", @original_anthropic)
    restore_env("TAVILY_API_KEY", @original_tavily)
    ApiCredentials.reset_credentials_source!
  end

  test "anthropic_api_key prefers ENV" do
    ENV["ANTHROPIC_API_KEY"] = "from-env"

    assert_equal "from-env", ApiCredentials.anthropic_api_key
  end

  test "tavily_api_key prefers ENV" do
    ENV["TAVILY_API_KEY"] = "tvly-from-env"

    assert_equal "tvly-from-env", ApiCredentials.tavily_api_key
  end

  test "raises KeyError when anthropic key missing from env and credentials" do
    ENV.delete("ANTHROPIC_API_KEY")
    ApiCredentials.credentials_source = NullCredentials.new

    error = assert_raises(KeyError) { ApiCredentials.anthropic_api_key }
    assert_match(/anthropic/i, error.message)
  end

  private

  def restore_env(key, value)
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end

  class NullCredentials
    def dig(*)
      nil
    end
  end
end
