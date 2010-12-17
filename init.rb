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
    Help.group("Logging") do |group|
      group.command "logs",           "fetch recent logs"
      group.command "logs --tail",    "realtime logs tail"
      group.command "logs:drains",    "list syslog drains"
      group.command "logs:drains add <url>",     "add a syslog drain"
      group.command "logs:drains remove <url>",  "remove a syslog drain"
      group.command "logs:drains clear",         "remove all syslog drains"
    end

    def index
      init_colors

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
        display_with_colors chk
      end
    end

    def drains
      if args.empty?
        puts heroku.list_drains(app)
        return
      end

      case args.shift
        when "add"
          url = args.shift
          puts heroku.add_drain(app, url)
          return
        when "remove"
          url = args.shift
          puts heroku.remove_drain(app, url)
          return
        when "clear"
          puts heroku.clear_drains(app)
          return
      end
      raise(CommandFailed, "usage: heroku logs:drains <add | remove | clear>")
    end

    def init_colors
      require 'term/ansicolor'
      @assigned_colors = {}

      trap("INT") do
        puts Term::ANSIColor.reset
        exit
      end
    rescue LoadError
    end

    COLORS = %w( cyan yellow green magenta red )

    def display_with_colors(log)
      return if log.empty?

      if !@assigned_colors
        puts log
        return
      end

      header, identifier, body = parse_log(log)
      @assigned_colors[identifier] ||= COLORS[@assigned_colors.size % COLORS.size]
      print Term::ANSIColor.send(@assigned_colors[identifier])
      print header
      print Term::ANSIColor.reset
      print body
      puts
    end

    def parse_log(log)
      return unless parsed = log.match(/^(.*\[(\w+)([\d\.]+)?\]:)(.*)?$/)
      [1, 2, 4].map { |i| parsed[i] }
    end
  end
end
