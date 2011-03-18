require 'helper'

class TestAXElement < MiniTest::Unit::TestCase

  def test_can_click
    assert AX::Element.ancestors.include?(AX::Traits::Clicking)
  end

  def test_can_wait_for_notifications
    assert AX::Element.ancestors.include?(AX::Traits::Notifications)
  end

end
