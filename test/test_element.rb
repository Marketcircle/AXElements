require 'helper'

class TestAXElement < MiniTest::Unit::TestCase
  def test_can_click
    assert AX::Element.ancestors.include?(AX::Traits::Clicking)
  end

  def test_can_wait_for_notifications
    assert AX::Element.ancestors.include?(AX::Traits::Notifications)
  end
end

class TestAXElementMethodMissing < MiniTest::Unit::TestCase
  def test_finds_attributes
    assert_equal 'Dock', AX::DOCK.title
  end

  def test_finds_actions
    skip 'This test is too invasive, need to find another way or add a test option'
  end

  def test_search_one_level_deep
    assert_equal 'AX::List', AX::DOCK.list.class.to_s
  end

  def test_search_multiple_levels_deep
    assert_equal 'AX::ApplicationDockItem', AX::DOCK.application_dock_item.class.to_s
  end

  def test_search_works_with_plural
    ret = AX::DOCK.lists
    assert_instance_of Array, ret
    assert_instance_of AX::List, ret.first
  end
end
end
