require 'rubygems'
require 'ax_elements'

# We want to launch the test app and make sure it responds to
# accessibility queries, but that is difficult, so we just sleep
APP_BUNDLE_URL = NSURL.fileURLWithPath File.expand_path './test/fixture/Release/AXElementsTester.app'
APP_BUNDLE_IDENTIFIER = 'com.marketcircle.AXElementsTester'

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

  def assert_instance_of_boolean value
    message = "Expected #{value.inspect} to be a boolean"
    assert value.is_a?(TrueClass) || value.is_a?(FalseClass), message
  end

  def self.pid_from name # sneaky naming
    NSWorkspace.sharedWorkspace.runningApplications.find do |app|
      app.bundleIdentifier == name
    end.processIdentifier
  end

  # You may need this to help track down an issue if a test is crashing MacRuby
  # def self.test_order
  #   :alpha
  # end

  def self.bench_range
    bench_exp 100, 100_000
  end

  PID = pid_from APP_BUNDLE_IDENTIFIER
  REF = AXUIElementCreateApplication(PID)

end

##
# Just pretend that you didnt' see this hack
class AX::Element
  attr_reader :ref
end
