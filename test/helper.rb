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

class TestAX < MiniTest::Unit::TestCase

  def self.pid_for_app name
    APPS.find { |app| app.localizedName == name }.processIdentifier
  end

  # returns raw attribute
  def self.attribute_for element, attr
    ptr = Pointer.new(:id)
    AXUIElementCopyAttributeValue( element, attr, ptr )
    ptr[0]
  end

  APPS       = NSWorkspace.sharedWorkspace.runningApplications
  DOCK_PID   = pid_for_app 'Dock'
  FINDER_PID = pid_for_app 'Finder'
  SYSTEM     = AXUIElementCreateSystemWide()
  DOCK       = AXUIElementCreateApplication(DOCK_PID)
  FINDER     = AXUIElementCreateApplication(FINDER_PID)
  LIST       = attribute_for( DOCK, KAXChildrenAttribute ).first

  def attribute_for element, attr
    self.class.attribute_for element, attr
  end

  def children_for element
    attribute_for element, KAXChildrenAttribute
  end

  def action_for element, action
    AXUIElementPerformAction( element, action )
  end

  def element_at_pos point
    ptr     = Pointer.new( '^{__AXUIElement}' )
    system  = AXUIElementCreateSystemWide()
    AXUIElementCopyElementAtPosition( system, point.x, point.y, ptr )
    ptr[0]
  end

  def set_attribute_for element, attribute, value
    AXUIElementSetAttributeValue( element, attribute, value )
  end

  # turn on full logging, yield, set log level back to previous
  def with_logging level = Logger::DEBUG
    original_level = AX.log.level
    AX.log.level   = level
    yield
    AX.log.level   = original_level
  end

end
