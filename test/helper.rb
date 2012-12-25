require 'accessibility/core'
framework 'Cocoa' if on_macruby?

# We want to launch the test app and make sure it responds to
# accessibility queries, but that is difficult to know at what
# point it will start to respond, so we just sleep
APP_BUNDLE_PATH       = File.expand_path './test/fixture/Release/AXElementsTester.app'
APP_BUNDLE_IDENTIFIER = 'com.marketcircle.AXElementsTester'

`open #{APP_BUNDLE_PATH}`
sleep 3

at_exit do
  `killall AXElementsTester`
end


require 'test/runner'


class MiniTest::Unit::TestCase
  # needs to be defined in the class, there is a TOPLEVEL::PID
  PID = pid_for APP_BUNDLE_IDENTIFIER
  REF = Accessibility::Element.application_for PID
end
