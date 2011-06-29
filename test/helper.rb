require 'rubygems'

require 'AXElements'
require 'stringio'

# We want to launch the test app and make sure it responds to
# accessibility queries, but that is difficult, so we just sleep
APP_BUNDLE_IDENTIFIER = 'com.marketcircle.AXElementsTester'

if NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier  APP_BUNDLE_IDENTIFIER,
                                                     options: NSWorkspaceLaunchAsync,
                              additionalEventParamDescriptor: nil,
                                            launchIdentifier: nil
  sleep 3 # we have no good way of knowing exactly when the app is ready
else
  $stderr.puts 'You need to build the fixture app before running tests'
  $stderr.puts 'Run `rake fixture`'
  exit 3
end

# Make sure the test app is closed when testing finishes
at_exit do
  NSWorkspace.sharedWorkspace.runningApplications.find do |app|
    app.bundleIdentifier == APP_BUNDLE_IDENTIFIER
  end.terminate
end


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

module AXHelpers
  def pid_for name
    NSWorkspace.sharedWorkspace.runningApplications.find do |app|
      app.bundleIdentifier == name
    end.processIdentifier
  end
end

class TestAX < MiniTest::Unit::TestCase
  include AXHelpers
  extend AXHelpers

  # execute the block with full logging turned on
  def with_logging level = Logger::DEBUG
    original_level = Accessibility.log.level
    Accessibility.log.level = level
    yield
    Accessibility.log.level = original_level
  end
end
