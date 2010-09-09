class Heroku::Client
  def logplex(app_name, options = {})
    url = get("/apps/#{app_name}/logplex", options).to_s
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

class Heroku::Command::Logplex
  def tail
    heroku.logplex(app)
  end
end
