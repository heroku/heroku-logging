require "rubygems"
require "rspec"
require "heroku"
require "heroku/command"
require "init"

# class with same interface as Term::ANSIColor
class TestColors
  Heroku::Command::Logs::COLORS.each do |color|
    define_method(color) do
      "<#{color.upcase}>"
    end
  end

  def reset
    "<RESET>"
  end
end

describe Heroku::Command::Logs do
  let(:client) { Heroku::Command::Logs.new ['--app', 'myapp'] }
  before do
    client.init_colors TestColors.new
  end

  def colorize(chunk)
    client.format_with_colors(chunk)
  end

  it "formats lines adding a color to the process description" do
    colorize("date app[web.1]:   log").should == "<CYAN>date app[web.1]:<RESET>   log"
  end

  it "can format multiple lines" do
    colorize("[web.1]: a\n[worker.1]: b").should == "<CYAN>[web.1]:<RESET> a\n<YELLOW>[worker.1]:<RESET> b"
  end
end