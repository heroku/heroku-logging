class Heroku::Client
  def read_logs(app_name, options)
    query = "&" + options.join("&") unless options.empty?
    url = get("/apps/#{app_name}/logs?logplex=true#{query}").to_s
    if url == 'Use old logs'
      puts get("/apps/#{app_name}/logs").to_s
    else
      uri  = URI.parse(url);
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.read_timeout = 60 * 60 * 24

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
  end

  def log_info(app_name)
    get("/apps/#{app_name}/logs/info").to_s.gsub(/^\s*$/, '')
  end

  def list_drains(app_name)
    get("/apps/#{app_name}/logs/drains").to_s
  end

  def add_drain(app_name, url)
    post("/apps/#{app_name}/logs/drains", "url=#{url}").to_s
  end

  def remove_drain(app_name, url)
    delete("/apps/#{app_name}/logs/drains?url=#{URI.escape(url)}").to_s
  end

  def clear_drains(app_name)
    delete("/apps/#{app_name}/logs/drains", {}).to_s
  end
end

module Heroku::Command
  class Logs < BaseWithApp
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

    def drains
      case args.shift
      when "clear"
        puts heroku.clear_drains(app)
        return
      end
      puts heroku.list_drains(app)
    end

    def drain
      case args.shift
        when "add"
          url = args.shift unless args.empty?
          puts heroku.add_drain(app, url)
          return
        when "remove"
          url = args.shift unless args.empty?
          puts heroku.remove_drain(app, url)
          return
      end
      puts "Unknown or malformed drain command"
    end

  end
end
