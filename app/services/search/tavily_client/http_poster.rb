require "net/http"
require "uri"

module Search
  class TavilyClient
    class HttpPoster
      Response = Data.define(:status, :body)

      def post(url, body:, headers:)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"

        request = Net::HTTP::Post.new(uri)
        headers.each { |key, value| request[key] = value }
        request.body = body

        response = http.request(request)
        Response.new(status: response.code.to_i, body: response.body)
      end
    end
  end
end
