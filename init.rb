class Heroku::Client
  def logplex(app_name, options = {})
    url = get("/apps/#{app_name}/logplex", options).to_s
    puts "DEBUG: connecting to #{url}"
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

  def logplex_add(app_name, options = {})
    puts post("/apps/#{app_name}/logplex", options).to_s
  end

  def logplex_remove(app_name, options = {})
    puts delete("/apps/#{app_name}/logplex", options).to_s
  end
end

module Heroku::Command
  class Logplex < BaseWithApp
    def index
      ## make this do something other than tail?
      heroku.logplex(app)
    end

    def tail
      heroku.logplex(app)
    end

    def add
      heroku.logplex_add(app)
    end

    def remove
      heroku.logplex_remove(app)
    end
  end
end
