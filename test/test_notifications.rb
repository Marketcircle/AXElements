class TestAXElement < MiniTest::Unit::TestCase
  def test_can_wait_for_notifications
    assert AX::Element.instance_methods.include?(:wait_for_notification)
  end
end

class TestAXElementNotifications < MiniTest::Unit::TestCase
end
