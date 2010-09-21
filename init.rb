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
          yield chunk
        end
      end
    end
  end

  def enable_logplex(app_name)
    post("/apps/#{app_name}/logplex", {}).to_s
  end

  def disable_logplex(app_name)
     delete("/apps/#{app_name}/logplex", {}).to_s
  end

  def add_drain(app_name, options=[])
    post("/apps/#{app_name}/logplex/drains", options.join("&")).to_s
  end

  def remove_drain(app_name, drain_name)
    delete("/apps/#{app_name}/logplex/drains/#{drain_name}", {}).to_s
  end
end

module Heroku::Command
  class Logplex < BaseWithApp
    Help.group("logplex") do |group|
      group.command "logplex:enable",    "enable logplex service"
      group.command "logplex:disable",   "disable logplex service"
      group.command "logplex [options]", "show logplex logs"
      group.command "logplex --tail",    "realtime tail of logplex logs"
      group.command "logplex:drain add [options]", "add an instance that will receive log messages"
      group.command "logplex:drain remove [options]", "remove an instance"
    end

    def index
      options = []
      until args.empty? do
        case args.shift
          when "-t", "--tail"   then options << "tail=1"
          when "-n", "--num"    then options << "num=#{args.shift.to_i}"
          when "-p", "--ps"     then options << "ps=#{URI.encode(args.shift)}"
          when "-s", "--source" then options << "source=#{URI.encode(args.shift)}"
          end
      end
      heroku.read_logplex(app, options) do |chk|
        puts chk
      end
    end

    def disable
      puts heroku.disable_logplex(app)
    end

    def enable
      puts heroku.enable_logplex(app)
    end

    def drain
      case args.shift
        when "add"
          options = []
          until args.empty? do
            case args.shift
              when "-n", "--name"   then options << "name=#{URI.encode(args.shift)}"
              when "-h", "--host"    then options << "host=#{URI.encode(args.shift)}"
              when "-p", "--port"     then options << "port=#{args.shift.to_i}"
              end
          end
          puts heroku.add_drain(app, options)
          return
        when "remove"
          until args.empty? do
            case args.shift
              when "-n", "--name"
                name = URI.encode(args.shift)
                puts heroku.remove_drain(app, name)
                return
              end
          end
      end
      puts "Unknown or malformed drain command"
    end

  end
end
