require 'AXElements'

require 'StringIO'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'vendor_test'))
require 'minitest/autorun'

$init_output = StringIO.new
AX.log = Logger.new $init_output

class MiniTest::Unit::TestCase
  def setup
    @log_output = StringIO.new
    AX.log = Logger.new @log_output
  end
end


##
# Import of minitest/pride from minitest-macruby-pride
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
