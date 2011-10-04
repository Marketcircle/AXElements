require 'rubygems'

require 'ax_elements'
require 'stringio'

# Accessibility.log.level = Logger::DEBUG

# We want to launch the test app and make sure it responds to
# accessibility queries, but that is difficult, so we just sleep
APP_BUNDLE_URL = NSURL.fileURLWithPath File.expand_path './test/fixture/Release/AXElementsTester.app'

error = Pointer.new :id
TEST_APP = NSWorkspace.sharedWorkspace.launchApplicationAtURL APP_BUNDLE_URL,
                                                     options: NSWorkspaceLaunchAsync,
                                               configuration: {},
                                                       error: error
if TEST_APP.nil?
  $stderr.puts 'You need to build AND run the fixture app before running tests'
  $stderr.puts 'Run `rake fixture`'
  exit 3
else
  sleep 3 # I haven't yet figured out a good way of knowing exactly
          # when the app is ready
  # Make sure the test app is closed when testing finishes
  at_exit do TEST_APP.terminate end
end


gem     'minitest'
require 'minitest/autorun'

# preprocessor powers, assemble!
if ENV['BENCH']
  require 'minitest/benchmark'
else
  require'minitest/pride'
end


class MiniTest::Unit::TestCase
  # You may need this to help track down an issue if a test is crashing MacRuby
  # def self.test_order
  #   :alpha
  # end

  def assert_instance_of_boolean value
    message = "Expected #{value.inspect} to be a boolean"
    assert value.is_a?(TrueClass) || value.is_a?(FalseClass), message
  end

  def self.bench_range
    bench_exp 10, 10_000
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

  # returns raw attribute
  def attribute_for element, attr
    ptr = Pointer.new :id
    AXUIElementCopyAttributeValue(element, attr, ptr)
    ptr[0]
  end

  def children_for element
    attribute_for element, KAXChildrenAttribute
  end

  def value_for element
    attribute_for element, KAXValueAttribute
  end

  def action_for element, action
    AXUIElementPerformAction(element, action)
  end

  # remember to wrap structs in an AXValueRef
  def set_attribute_for element, attr, value
    AXUIElementSetAttributeValue(element, attr, value)
  end
end

class TestAX < MiniTest::Unit::TestCase
  include AXHelpers
  extend AXHelpers

  APP_BUNDLE_IDENTIFIER = 'com.marketcircle.AXElementsTester'
  PID = pid_for APP_BUNDLE_IDENTIFIER
  REF = AXUIElementCreateApplication(PID)

  # execute the block with full logging turned on
  def with_logging level = Logger::DEBUG
    original_level = Accessibility.log.level
    Accessibility.log.level = level
    yield
    Accessibility.log.level = original_level
  end
end

##
# Just pretend that you didnt' see this hack
class AX::Element
  attr_reader :ref
end
