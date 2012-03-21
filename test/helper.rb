framework 'Cocoa'

# We want to launch the test app and make sure it responds to
# accessibility queries, but that is difficult, so we just sleep
APP_BUNDLE_URL = NSURL.fileURLWithPath File.expand_path './test/fixture/Release/AXElementsTester.app'
APP_BUNDLE_IDENTIFIER = 'com.marketcircle.AXElementsTester'

error    = Pointer.new :id
TEST_APP = NSWorkspace.sharedWorkspace.launchApplicationAtURL APP_BUNDLE_URL,
                                                     options: NSWorkspaceLaunchAsync,
                                               configuration: {},
                                                       error: error
if TEST_APP.nil?
  $stderr.puts 'You need to build AND run the fixture app before running tests'
  $stderr.puts 'Run `rake fixture`'
  exit 3
else
  sleep 2 # Instead of using high level features of AXElements that we are
          # testing, I think it is just safer to sleep
  # Make sure the test app is closed when testing finishes
  at_exit do TEST_APP.terminate end
end

# Figure out if we are testing a compiled version of AXElements, since some
# tests will fail due to incomplete MacRuby features.
RUNNING_COMPILED =
  $LOADED_FEATURES.find { |file| file.match /ax_elements.rbo/ }

require 'test_runner'
require 'ax_elements'

class MiniTest::Unit::TestCase

  def self.pid_from name # sneaky naming
    NSWorkspace.sharedWorkspace.runningApplications.find do |app|
      app.bundleIdentifier == name
    end.processIdentifier
  end

  PID = pid_from APP_BUNDLE_IDENTIFIER
  REF = AXUIElementCreateApplication(PID)

end

##
# Just pretend that you didn't see this hack
class AX::Element
  attr_reader :ref
end

# Force this to be on for testing
Accessibility::Debug.on = true
