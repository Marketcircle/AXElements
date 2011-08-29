class TestCore < TestAX

  WINDOW = attribute_for REF, KAXMainWindowAttribute

  def child name
    children_for(WINDOW).find do |item|
      attribute_for(item, KAXRoleAttribute) == name
    end
  end

  def slider
    @@slider ||= child KAXSliderRole
  end

  def check_box
    @@check_box ||= child KAXCheckBoxRole
  end

  def search_box
    @@search_box ||= child KAXTextFieldRole
  end

  def button
    @@button ||= child KAXButtonRole
  end

  def static_text
    @@static_text ||= child KAXStaticTextRole
  end

  def yes_button
    @@yes_button ||= children_for(WINDOW).find do |item|
      if attribute_for(item, KAXRoleAttribute) == KAXButtonRole
        attribute_for(item, KAXTitleAttribute) == 'Yes'
      end
    end
  end

end


##
# AFAICT every accessibility object **MUST** have attributes, so
# there are no tests to check what happens when they do not exist;
# though I am quite sure that AXElements will explode.
class TestAttrsOfElement < TestCore

  def attrs
    @@attrs ||= AX.attrs_of_element REF
  end

  def test_returns_array_of_strings
    assert_instance_of String, attrs.first
  end

  def test_make_sure_certain_attributes_are_provided
    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXRoleDescriptionAttribute
  end

  def test_other_attributes_that_the_app_should_have
    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute
  end

end


class TestAttrCountOfElement < TestCore

  def test_returns_number_of_children
    assert_equal children_for(REF).size, AX.attr_count_of_element(REF, KAXChildrenAttribute)
    assert_equal 0, AX.attr_count_of_element(button, KAXChildrenAttribute)
  end

  # @todo there are things we care about?

end


class TestAttrOfElementGetsCorrectAttribute < TestCore

  def test_title_is_title
    assert_equal 'AXElementsTester', AX.attr_of_element(REF, KAXTitleAttribute)
  end

  # @note the app gives CGRectZero in screen coordinates, and then they are
  #       flipped for us to, so we need to flip them again
  def test_custom_lol_is_rect
    point         = CGPointZero.dup
    point.y       = NSScreen.mainScreen.frame.size.height
    expected_rect = CGRect.new point, CGSizeZero
    ret           = AX.attr_of_element WINDOW, 'AXLol'
    ptr           = Pointer.new CGRect.type
    AXValueGetValue(ret, 3, ptr)
    assert_equal expected_rect, ptr[0]
  end

  def test_hidden_is_hidden_value
    assert_equal false, AX.attr_of_element(REF, KAXHiddenAttribute)
  end

end


class TestAttrOfElementErrors < TestCore
  include LoggingCapture

  def test_logs_message_for_non_existant_attributes
    with_logging do AX.attr_of_element REF, 'MADEUPATTRIBUTE' end
    assert_match /#{KAXErrorAttributeUnsupported}/, @log_output.string
  end

end


class TestAttrOfElementWritable < TestCore

  def test_true_for_writable_attribute
    assert AX.attr_of_element_writable?(WINDOW, KAXMainAttribute)
  end

  def test_false_for_non_writable_attribute
    refute AX.attr_of_element_writable?(REF, KAXTitleAttribute)
  end

  def test_false_for_non_existante_attribute
    refute AX.attr_of_element_writable?(REF, 'FAKE')
  end

end


class TestSetAttrOfElement < TestCore

  def test_set_a_slider
    [25, 75, 50].each do |value|
      AX.set_attr_of_element slider, KAXValueAttribute, value
      assert_equal value, value_for(slider)
    end
  end

  def test_set_a_text_field
    [Time.now.to_s, ''].each do |value|
      AX.set_attr_of_element(search_box, KAXValueAttribute, value)
      assert_equal value, value_for(search_box)
    end
  end

end


class TestActionsOfElement < TestCore

  def test_works_when_there_are_no_actions
    assert_empty AX.actions_of_element REF
  end

  def test_returns_array_of_strings
    assert_instance_of String, AX.actions_of_element(yes_button).first
  end

  def test_make_sure_certain_actions_are_present
    actions = AX.actions_of_element slider
    assert_includes actions, KAXIncrementAction
    assert_includes actions, KAXDecrementAction
  end

end


class TestActionOfElement < TestCore

  def test_check_a_check_box
    2.times do # twice so it should be back where it started
      value = value_for check_box
      AX.action_of_element check_box, KAXPressAction
      refute_equal value, value_for(check_box)
    end
  end

  def test_sliding_the_slider
    value = attribute_for slider, KAXValueAttribute
    AX.action_of_element slider, KAXIncrementAction
    assert attribute_for(slider, KAXValueAttribute) > value

    value = attribute_for slider, KAXValueAttribute
    AX.action_of_element slider, KAXDecrementAction
    assert attribute_for(slider, KAXValueAttribute) < value
  end

end


class TestKeyboardAction < TestCore

  SYSTEM = AXUIElementCreateSystemWide()

  def post string
    set_attribute_for search_box, KAXFocusedAttribute, true
    AX.keyboard_action REF, string
    # sleep 0.01
    assert_equal string, attribute_for(search_box, KAXValueAttribute)
  ensure
    button = children_for(search_box).find { |x| x.class == AX::Button }
    action_for button, KAXPressAction
  end

  def test_uppercase_letters
    post 'HELLO, WORLD'
  end

  def test_numbers
    post '42'
  end

  def test_letters
    post 'the cake is a lie'
  end

  def test_escape_sequences
    post "\s"
  end

end


class TestAXParamAttrsOfElement < TestCore

  def test_empty_for_dock
    assert_empty AX.param_attrs_of_element REF
  end

  def test_not_empty_for_search_field
    assert_includes AX.param_attrs_of_element(static_text), KAXStringForRangeParameterizedAttribute
    assert_includes AX.param_attrs_of_element(static_text), KAXLineForIndexParameterizedAttribute
    assert_includes AX.param_attrs_of_element(static_text), KAXBoundsForRangeParameterizedAttribute
  end

end


class TestAXParamAttrOfElement < TestCore

  def test_contains_proper_info
    attr = AX.param_attr_of_element(static_text,
                                    KAXStringForRangeParameterizedAttribute,
                                    CFRange.new(0, 5).to_axvalue)
    assert_equal 'AXEle', attr
  end

  def test_get_attributed_string
    attr = AX.param_attr_of_element(static_text,
                                    # this is why we need name tranformers
                                    KAXAttributedStringForRangeParameterizedAttribute,
                                    CFRange.new(0, 5).to_axvalue)
    assert_kind_of NSAttributedString, attr
    assert_equal 'AXEle', attr.string
  end

end


class TestAXNotifications < TestCore

  # custom notification name
  CHEEZBURGER = 'Cheezburger'

  SHORT_TIMEOUT = 0.1
  TIMEOUT       = 1.0

  def radio_group
    @radio_group ||= child KAXRadioGroupRole
  end

  def radio_gaga
    @@gaga ||= children_for(radio_group).find do |item|
      attribute_for(item, KAXTitleAttribute) == 'Gaga'
    end
  end

  def radio_flyer
    @@flyer ||= children_for(radio_group).find do |item|
      attribute_for(item, KAXTitleAttribute) == 'Flyer'
    end
  end

  def menu_bar_menu
    @@menu_bar_menu ||= children_for(children_for(REF).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXMenuBarRole
    end).find do |item|
      attribute_for(item, KAXTitleAttribute) == 'File'
    end
  end

  def teardown
    if attribute_for(radio_gaga, KAXValueAttribute) == 1
      action_for radio_flyer, KAXPressAction
    end
  end

  def test_works_without_a_block
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification)
    start = Time.now
    action_for radio_gaga, KAXPressAction

    AX.wait_for_notif(TIMEOUT)
    assert_in_delta Time.now, start, TIMEOUT
  end

  def test_decides_to_continue_based_on_block_return_value
    got_callback   = false
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) do |_,_|
      got_callback = true
      false
    end
    action_for radio_gaga, KAXPressAction

    start = Time.now
    AX.wait_for_notif(SHORT_TIMEOUT)
    refute_in_delta Time.now, start, SHORT_TIMEOUT
  end

  def test_pauses_at_most_timeout_seconds
    skip 'Test is order dependent right now'
    start = Time.now
    ret   = AX.wait_for_notif(SHORT_TIMEOUT)
    done  = Time.now

    refute ret, 'Failed to wait'
    assert_in_delta (done - start), SHORT_TIMEOUT, 0.01
  end

  def test_listening_to_app_catches_everything
    got_callback   = false
    AX.register_for_notif(REF, KAXValueChangedNotification) do |el, notif|
      got_callback = true
    end
    action_for radio_gaga, KAXPressAction
    AX.wait_for_notif(TIMEOUT)
    assert got_callback
  end

  def test_works_with_custom_notifications
    got_callback = false
    button = yes_button
    AX.register_for_notif(yes_button, CHEEZBURGER) do |_,_|
      got_callback = true
    end
    action_for yes_button, KAXPressAction
    AX.wait_for_notif(TIMEOUT)
    assert got_callback
  end

  def test_returns_the_observer_notif_tuple
    tuple = AX.register_for_notif(yes_button, CHEEZBURGER) do |_,_| end
    # can't really test for a specific observer...
    assert_equal yes_button, tuple.first
    assert_equal CHEEZBURGER, tuple[1]
  end

  # there didn't seem to be a good way to unit test the cache...
  # so this covers the regular workflow
  def test_cache_is_updated_properly
    notif    = [REF, KAXValueChangedNotification]
    callback = false

    AX.register_for_notif *notif do |_,_| callback = true end
    assert AX.notifs.has_value? notif

    set_attribute_for search_box, KAXValueAttribute, 'beef cake'

    AX.wait_for_notif TIMEOUT
    assert callback
    refute AX.notifs.has_value? notif

  ensure
    set_attribute_for search_box, KAXValueAttribute, ''
  end
  def test_can_unregister_all_notifs
    skip
  end

end


class TestElementAtPosition < TestCore

  def test_returns_a_button_when_i_give_the_coordinates_of_a_button
    point = attribute_for button, KAXPositionAttribute
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(point, KAXValueCGPointType, ptr)
    point = ptr[0]
    element = AX.element_at_point(*point.to_a)
    assert_equal button, element
  end

end


class TestAXPIDThings < TestCore

  def test_app_for_pid_returns_raw_element
    ret  = AX.application_for_pid PID
    role = attribute_for ret, KAXRoleAttribute
    assert_equal KAXApplicationRole, role
  end

  def test_app_for_pid_raises_if_pid_is_zero
    assert_raises ArgumentError do
      AX.application_for_pid 0
    end
    assert_raises ArgumentError do
      AX.application_for_pid -1
    end
  end

  def test_pid_for_app
    assert_equal PID, AX.pid_of_element(REF)
  end

  def test_pid_for_dock_app_is_docks_pid
    assert_equal PID, AX.pid_of_element(WINDOW)
  end

end


# I'd prefer to not to be directly calling the log method bypassing
# the fact that it is a private method
class TestLogAXCall < TestCore
  include LoggingCapture

  def test_looks_up_code_properly
    with_logging { AX.send(:log_error, REF, KAXErrorAPIDisabled) }
    assert_match /API Disabled/, @log_output.string
    with_logging { AX.send(:log_error, REF, KAXErrorNotImplemented) }
    assert_match /Not Implemented/, @log_output.string
  end

  def test_handles_unknown_error_codes
    with_logging { AX.send(:log_error, REF, 1234567) }
    assert_match /UNKNOWN ERROR CODE/, @log_output.string
  end

end
