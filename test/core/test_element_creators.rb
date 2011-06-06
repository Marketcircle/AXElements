class TestElementAtPosition < MiniTest::Unit::TestCase

  # this test will break with full screen apps :(
  def test_returns_a_menubar_for_coordinates_10_0
    item = AX.element_at_position( 10, 0 )
    assert_instance_of AX::MenuBarItem, item
  end

end


class TestApplicationForPID < MiniTest::Unit::TestCase

  def test_makes_an_app
    assert_instance_of AX::Application, AX.application_for_pid(TestCore::FINDER_PID)
  end

end
