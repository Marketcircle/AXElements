require 'core/helper'

class TestAXActionsOfElement < TestAX

  def test_works_when_there_are_no_actions
    assert_empty AX.actions_of_element(DOCK)
  end

  def test_returns_array_of_strings
    assert_instance_of String, AX.actions_of_element(finder_dock_item).first
  end

  def test_make_sure_certain_actions_are_present
    actions = AX.actions_of_element(finder_dock_item)
    assert actions.include?(KAXPressAction)
    assert actions.include?(KAXShowMenuAction)
  end

end

class TestAXPerformActionOfElement < TestAX

  def dock_kids
    attribute_for finder_dock_item, KAXChildrenAttribute
  end

  def test_show_a_dock_menu
    before_action_kid_count = dock_kids.count
    AX.action_of_element( finder_dock_item, KAXShowMenuAction )
    assert dock_kids.count > before_action_kid_count
  end

  # # @todo not a high priority
  # def test_press_a_button
  # end

end

class TestAXPostKBString < TestAX

  # this test can fail for strange keyboard layouts (e.g. programmer's dvorak)
  def test_post_to_system
    spotlight_text_field do |field|
      string = '123'
      AX.keyboard_action( SYSTEM, string )
      sleep 0.1
      assert_equal string, attribute_for( field, KAXValueAttribute )
    end
  end

#  # @todo not a high priority
#  def test_post_to_finder
#  end

end

