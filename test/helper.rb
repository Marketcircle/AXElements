require 'rubygems'

require 'AXElements'
require 'stringio'

gem     'minitest-macruby-pride'
require 'minitest/autorun'
require 'minitest/pride'

class MiniTest::Unit::TestCase
  def assert_instance_of_boolean value
    message = "Expected #{value.inspect} to be a boolean"
    assert value.is_a?(TrueClass) || value.is_a?(FalseClass), message
  end
end

##
# A mix in module to allow capture of logs
module LoggingCapture
  def setup
    super
    @log_output = StringIO.new
    Accessibility.log = Logger.new @log_output
  end
end

class TestAX < MiniTest::Unit::TestCase
  # We want to launch the test app and make sure it responds to
  # accessibility queries, but that is difficult, so we just sleep

  APP_BUNDLE_IDENTIFIER = 'com.marketcircle.AXElementsTester'

  NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier  APP_BUNDLE_IDENTIFIER,
                                                    options: NSWorkspaceLaunchAsync,
                             additionalEventParamDescriptor: nil,
                                           launchIdentifier: nil
  sleep 3
  at_exit { 'kill the app' }

  # execute the block with full logging turned on
  def with_logging level = Logger::DEBUG
    original_level = Accessibility.log.level
    Accessibility.log.level = level
    yield
    Accessibility.log.level = original_level
  end
end
