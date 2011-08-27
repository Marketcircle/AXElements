class TestAccessibilityLanguageActions < TestAX

  # LSP FTW
  class Language
    include Accessibility::Language
  end

  # mocking like a pro
  class LanguageTest < AX::Element
    attr_reader :called_action
    def perform_action name
      @called_action = name
    end
  end

  def setup
    @language = Language.new
    @element  = LanguageTest.new REF, AX.attrs_of_element(REF)
  end

  def test_static_actions_forward
    @language.cancel @element
    assert_equal :cancel, @element.called_action

    @language.confirm @element
    assert_equal :confirm, @element.called_action

    @language.decrement @element
    assert_equal :decrement, @element.called_action

    @language.delete @element
    assert_equal :delete, @element.called_action

    @language.increment @element
    assert_equal :increment, @element.called_action

    @language.pick @element
    assert_equal :pick, @element.called_action

    @language.press @element
    assert_equal :press, @element.called_action

    @language.cancel @element
    assert_equal :cancel, @element.called_action

    @language.raise @element
    assert_equal :raise, @element.called_action

    @language.show_menu @element
    assert_equal :show_menu, @element.called_action
  end

  def test_method_missing_forwards
    @language.zomg_method @element
    assert_equal :zomg_method, @element.called_action

    assert_raises NoMethodError do
      @language.zomg_method 'bacon'
    end
  end

  def test_raise_can_still_raise_exceptions
    assert_raises ArgumentError do
      @language.raise ArgumentError
    end
    assert_raises NoMethodError do
      @language.raise NoMethodError
    end
  end

end

class TestAccessibilityLanguage < TestAX

  def test_set_focus
    window  = attribute_for(REF, KAXMainWindowAttribute)
    group   = children_for(window).find do |element|
      attribute_for(element,KAXRoleAttribute) == KAXRadioGroupRole
    end
    buttons = children_for group
    # @todo swich focus between radio buttons in the radio group
  end

#   def test_set_arbitrary_attribute
#   end

#   def test_set_value
#   end

#   def test_type_sends_to_system_by_default
#   end

#   def test_type_can_send_to_arbitrary_applications
#   end

#   def test_register_for_notification_forwards_to_element
#   end

#   def test_wait_for_notification_forwards
#   end

#   def test_wait_for_notification_has_default
#   end

#   def test_move_mouse_to_accepts_many_inputs_but_forwards_cgpoint
#   end

#   def test_drag_mouse_accepts_many_inputs_but_forwards_cgpoint
#   end

#   def test_scroll_moves_mouse_to_object_first_if_given
#   end

#   def test_scroll_forwards_properly
#   end

#   def test_click_moves_mouse_to_object_first
#   end

#   def test_click_forwards
#   end

#   def test_right_click_moves_mouse_to_object_first
#   end

#   def test_right_click_forwards
#   end

#   def test_right_click_alias
#   end

#   def test_double_click_moves_mouse_to_object_first
#   end

#   def test_double_click_forwards
#   end

#   def test_show_about_window_for
#   end

#   def test_preferences_window_for
#   end

#   def test_is_mixed_into_toplevel
#   end

end
