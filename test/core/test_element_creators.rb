require 'core/helper'

class TestAXElementAtPosition < MiniTest::Unit::TestCase

  # this will break with full screen apps :(
  def test_returns_a_menubar_for_coordinates_10_0
    item = AX.element_at_position( CGPoint.new(10, 0) )
    assert_instance_of AX::MenuBarItem, item
  end

end


class TestAXApplicationForPID < MiniTest::Unit::TestCase

  def test_makes_an_app
    assert_instance_of AX::Application, AX.application_for_pid(TestAX::FINDER_PID)
  end

end
