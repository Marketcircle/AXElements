$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'vendor_test'))

require 'AXElements'
require 'StringIO'
require 'fileutils'
require 'minitest/autorun'

$init_output = StringIO.new
AX.log = Logger.new $init_output

class MiniTest::Unit::TestCase
  class << self
    def pid_for_app name
      apps = NSWorkspace.sharedWorkspace.runningApplications
      apps.find { |app| app.localizedName == name }.processIdentifier
    end
  end

  DOCK   = AXUIElementCreateApplication(pid_for_app 'Dock')
  FINDER = AXUIElementCreateApplication(pid_for_app 'Finder')

  def setup
    @log_output = StringIO.new
    AX.log = Logger.new @log_output
  end
end


##
# Import of minitest/pride from macruby-minitest-pride
class PrideIO
  attr_reader :io
  COLORS = (31..36).to_a
  COLORS_SIZE = COLORS.size

  def initialize io
    @io = io
    @index = 0
  end

  def print o
    case o
    when "." then
      @index += 1
      io.print "\e[#{COLORS[@index % COLORS_SIZE]}m*\e[0m"
    when "E", "F" then
      io.print "\e[41m\e[37m#{o}\e[0m"
    else
      io.print o
    end
  end

  def method_missing msg, *args
    io.send(msg, *args)
  end
end

MiniTest::Unit.output = PrideIO.new(MiniTest::Unit.output)
