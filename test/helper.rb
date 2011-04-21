require 'AXElements'
require 'StringIO'

require 'rubygems'
gem     'minitest-macruby-pride'
require 'minitest/autorun'
require 'minitest/pride'

$init_output = StringIO.new
AX.log = Logger.new $init_output

class MiniTest::Unit::TestCase
  def setup
    @log_output = StringIO.new
    AX.log = Logger.new @log_output
  end
end
