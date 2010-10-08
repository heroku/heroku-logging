class Heroku::Client
  def read_logs(app_name, options)
    query = "&" + options.join("&") unless options.empty?
    url = get("/apps/#{app_name}/logs?logplex=true#{query}").to_s
    uri  = URI.parse(url);
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.read_timeout = 0

    begin
      http.start do
        http.request_get(uri.path) do |request|
          request.read_body do |chunk|
            yield chunk
          end
        end
      end
    rescue Timeout::Error, EOFError
      abort("\n !    Request timed out")
    end
  end

  def log_info(app_name)
    get("/apps/#{app_name}/logs/info").to_s.gsub(/^\s*$/, '')
  end

  def add_drain(app_name, body)
    post("/apps/#{app_name}/logs/drains", body).to_s
  end

  def remove_drain(app_name, drain_name)
    delete("/apps/#{app_name}/logs/drains/#{drain_name}", {}).to_s
  end
end

module Heroku::Command
  class Logging < BaseWithApp
    Help.group("logs") do |group|
      group.command "logs [options]", "show logs"
      group.command "logs --tail",    "realtime tail of logs"
      group.command "logs:drain add [options]", "add an instance that will receive log messages"
      group.command "logs:drain remove [options]", "remove an instance"
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
      heroku.read_logs(app, options) do |chk|
        puts chk
      end
    end

    def info
      puts heroku.log_info(app)
    end

    def drain
      case args.shift
        when "add"
          name = host = port = nil
          until args.empty? do
            case args.shift
              when "-n", "--name" then name = URI.encode(args.shift)
              when "-h", "--host" then host = URI.encode(args.shift)
              when "-p", "--port" then port = args.shift.to_i
              end
          end
          if name.nil? || host.nil? || port.nil?
            puts "Usage:\theroku logs:drain add --name <name> --host <host> --port <port>"
          else
            puts heroku.add_drain(app, "name=#{name}&host=#{host}&port=#{port}")
          end
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
          puts "Usage:\theroku logs:drain remove --name <name>"
          return
      end
      puts "Unknown or malformed drain command"
    end

  end
end
