class TestActionsOfElement < TestCore

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


class TestActionOfElement < TestCore

  def dock_kids
    attribute_for finder_dock_item, KAXChildrenAttribute
  end

  def test_show_a_dock_menu
    before_action_kid_count = dock_kids.count
    AX.action_of_element(finder_dock_item, KAXShowMenuAction)
    assert dock_kids.count > before_action_kid_count
    AX.action_of_element(finder_dock_item, KAXShowMenuAction)
  end

  # # @todo not a high priority
  # def test_press_a_button
  # end

end


class TestKeyboardAction < TestCore

  # this test can fail for strange keyboard layouts (e.g. programmer's dvorak)
  def post_to_system string
    spotlight_text_field do |field|
      AX.keyboard_action( SYSTEM, string )
      sleep 0.01
      assert_equal string, attribute_for( field, KAXValueAttribute )
    end
  end

  def test_uppercase_letters
    post_to_system 'AM'
  end

  def test_numbers
    post_to_system '12'
  end

  def test_letters
    post_to_system 'am'
  end

  def test_escape_sequences
    post_to_system "\s"
  end

#  # @todo not a high priority
#  def test_post_to_finder
#  end

end
