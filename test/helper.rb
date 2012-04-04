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
  $stderr.puts 'You need to build AND run the fixture app once before running tests'
  $stderr.puts 'Run `rake run_fixture` to initalize the fixture'
  exit 3
else
  sleep 2 # Instead of using high level features of AXElements that we are
          # testing, I think it is just safer to sleep
  # Make sure the test app is closed when testing finishes
  at_exit do TEST_APP.terminate end
end


require 'test/runner'


class MiniTest::Unit::TestCase
  # needs to be defined in the class, there is a TOPLEVEL::PID
  PID = pid_for APP_BUNDLE_IDENTIFIER
  REF = AXUIElementCreateApplication(PID)
end


# Force this to be on for testing
# Accessibility::Debug.on = true
