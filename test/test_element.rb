require 'helper'

class TestAXElement < MiniTest::Unit::TestCase
  def test_can_click
    assert AX::Element.ancestors.include?(AX::Traits::Clicking)
  end

  def test_can_wait_for_notifications
    assert AX::DOCK.respond_to?(:wait_for_notification)
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

class TestAXElementRespondTo < MiniTest::Unit::TestCase
  def test_works_on_attributes
    assert AX::DOCK.respond_to?(:title)
  end

  def test_works_on_actions
    assert AX::DOCK.list.application_dock_item.respond_to?(:press)
  end

  def test_does_not_work_with_search_names
    refute AX::DOCK.respond_to?(:list)
  end

  def test_works_for_regular_methods
    assert AX::DOCK.respond_to?(:ref)
  end

  def test_returns_false_for_non_existant_methods
    refute AX::DOCK.respond_to?(:crazy_thing_that_cant_work)
  end
end
