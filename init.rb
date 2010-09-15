class Heroku::Client
  def read_logplex(app_name, options)
    query = "?" + options.join("&") unless options.empty?
    url = get("/apps/#{app_name}/logplex#{query}").to_s
    uri  = URI.parse(url);
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.start do
      http.request_get(uri.path) do |request|
        request.read_body do |chunk|
          puts chunk
        end
      end
    end
  end

  def init_logplex(app_name)
    post("/apps/#{app_name}/logplex", {}).to_s
  end

  def disable_logplex(app_name)
     delete("/apps/#{app_name}/logplex", {}).to_s
  end
end

module Heroku::Command
  class Logplex < BaseWithApp
    def index
      ## make this do something other than tail?
      options = []
      until args.empty? do
        case args.shift
          when "-t", "--tail"   then options << "tail=1"
          when "-n", "--num"    then options << "num=#{args.shift.to_i}"
          when "-p", "--pid"    then options << "pid=#{URI.encode(args.shift)}"
          when "-s", "--source" then options << "source=#{URI.encode(args.shift)}"
          end
      end
      heroku.read_logplex(app, options)
    end

    def disable
      puts heroku.disable_logplex(app)
    end

    def init
      puts heroku.init_logplex(app)
    end
  end
end
