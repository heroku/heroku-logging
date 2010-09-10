class Heroku::Client
  def logplex(app_name, options = {})
    url = get("/apps/#{app_name}/logplex", options).to_s
    puts "DEBUG: #{url}"
    ## all this allows us to read progressive output over https
    uri  = URI.parse(url);
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.start do
      http.request_get(uri.path) do |request|
        request.read_body do |chunk|
          puts chunk
        end
      end
    end
  end
end

module Heroku::Command
  class Logplex < BaseWithApp
    def index
      puts "hello world"
    end

    def tail
      puts "TAIL: #{app}"
      heroku.logplex(app)
    end
  end
end
