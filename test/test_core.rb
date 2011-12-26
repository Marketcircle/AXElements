class TestCore < TestAX

  def window
    @@window ||= attribute_for REF, KAXMainWindowAttribute
  end

  def child name
    children_for(window).find do |item|
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
    @@yes_button ||= children_for(window).find do |item|
      if attribute_for(item, KAXRoleAttribute) == KAXButtonRole
        attribute_for(item, KAXTitleAttribute) == 'Yes'
      end
    end
  end

  def web_area
    @@web_area ||= children_for(children_for(window).find do |item|
      if attribute_for(item, KAXRoleAttribute) == 'AXScrollArea'
        attribute_for(item, KAXDescriptionAttribute) == 'Test Web Area'
      end
    end).first
  end


  ##
  # AFAICT every accessibility object **MUST** have attributes, so
  # there are no tests to check what happens when they do not exist;
  # though I am quite sure that AXElements will explode.

  def test_attrs_is_array_of_strings
    attrs = AX.attrs_of_element REF

    refute_empty attrs

    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXRoleDescriptionAttribute

    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute
  end

  def test_attrs_handles_errors
    assert_raises ArgumentError do
      AX.attrs_of_element nil
    end

    # I'm having a hard time trying to figure out how to test the other
    # failure cases...
  end



  def test_attr_count_is_a_number
    x = children_for(REF).size
    assert_equal x, AX.attr_count_of_element(REF,    KAXChildrenAttribute)
    assert_equal 0, AX.attr_count_of_element(button, KAXChildrenAttribute)
  end

  def test_attr_count_handles_errors
    assert_raises ArgumentError do
      AX.attr_count_of_element REF, 'pie'
    end

    assert_raises ArgumentError do
      AX.attr_count_of_element nil, KAXChildrenAttribute
    end

    # Not sure how to trigger other failure cases reliably...
  end



  # At this layer, we only need to test a few things...

  def test_attr_value_is_correct
    assert_equal 'AXElementsTester', AX.attr_of_element(REF, KAXTitleAttribute)
    assert_equal false,              AX.attr_of_element(REF, KAXHiddenAttribute)
    assert_equal AXValueGetTypeID(), CFGetTypeID(AX.attr_of_element(window, KAXSizeAttribute))
  end

  def test_attr_value_is_nil_when_no_value_error_occurs
    assert_nil AX.attr_of_element(window, KAXGrowAreaAttribute)
  end

  def test_attr_value_handles_errors
    assert_raises RuntimeError do
      AX.attr_of_element REF, 'MADEUPATTRIBUTE'
    end
  end



  def test_role_pair_macro
    assert_equal [KAXStandardWindowSubrole, KAXWindowRole], AX.role_pair_for(window)
    assert_equal [nil, 'AXWebArea'],                        AX.role_pair_for(web_area)
  end

  def test_role_macro
    assert_equal KAXApplicationRole, AX.role_for(REF)
    assert_equal KAXWindowRole,      AX.role_for(window)
  end



  def test_attr_writable_correct_values
    assert AX.attr_of_element_writable?(window, KAXMainAttribute)
    refute AX.attr_of_element_writable?(REF,    KAXTitleAttribute)
  end

  def test_attr_writable_false_for_no_value_cases
    skip 'I am not aware of how to create such a case...'
    # refute AX.attr_of_element_writable?(REF, KAXChildrenAttribute)
  end

  def test_attr_writable_handles_errors
    assert_raises ArgumentError do
      AX.attr_of_element_writable? REF, 'FAKE'
    end

    # Not sure how to test other cases...
  end



  def test_set_attr_on_slider
    [25, 75, 50].each do |value|
      AX.set_attr_of_element slider, KAXValueAttribute, value
      assert_equal value, value_for(slider)
    end
  end

  def test_set_attr_on_text_field
    [Time.now.to_s, ''].each do |value|
      AX.set_attr_of_element(search_box, KAXValueAttribute, value)
      assert_equal value, value_for(search_box)
    end
  end

  def test_set_attr_handles_errors
    assert_raises ArgumentError do
      AX.set_attr_of_element REF, 'FAKE', true
    end

    # Not sure how to test other failure cases...
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

  def test_hyphen
    post '---'
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


# be very careful about cleaning up state after notification tests
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

  def teardown
    if attribute_for(radio_gaga, KAXValueAttribute) == 1
      action_for radio_flyer, KAXPressAction
    end
    AX.unregister_notifs
  end

  def test_break_if_ignoring
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) { |_,_| true }
    AX.instance_variable_set :@ignore_notifs, true

    action_for radio_gaga, KAXPressAction

    start = Time.now
    refute AX.wait_for_notif(SHORT_TIMEOUT)
    done  = Time.now

    refute_in_delta done, start, SHORT_TIMEOUT
  end

  def test_break_if_block_returns_falsey
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) { |_,_| false }
    action_for radio_gaga, KAXPressAction

    start = Time.now
    refute AX.wait_for_notif(SHORT_TIMEOUT)
    done  = Time.now

    refute_in_delta done, start, SHORT_TIMEOUT
  end

  def test_stops_if_block_returns_truthy
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) { |_,_| true }
    action_for radio_gaga, KAXPressAction
    assert AX.wait_for_notif(SHORT_TIMEOUT)
  end

  def test_returns_triple
    ret = AX.register_for_notif(radio_gaga, KAXValueChangedNotification) { |_,_| true }
    assert_equal AXObserverGetTypeID(), CFGetTypeID(ret[0])
    assert_equal radio_gaga, ret[1]
    assert_equal KAXValueChangedNotification, ret[2]
  end

  def test_wait_stops_waiting_when_notif_received
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) { |_,_| true }
    action_for radio_gaga, KAXPressAction

    start = Time.now
    AX.wait_for_notif(SHORT_TIMEOUT)
    done  = Time.now

    msg = 'Might fail if your machine is under heavy load'
    assert_in_delta done, start, 0.02, msg
  end

  def test_works_with_custom_notifs
    got_callback = false
    AX.register_for_notif(yes_button, CHEEZBURGER) do |_,_|
      got_callback = true
    end
    action_for yes_button, KAXPressAction
    AX.wait_for_notif(SHORT_TIMEOUT)
    assert got_callback, 'did not get callback'
  end

  def test_unregistering_clears_notif
    AX.register_for_notif(yes_button, CHEEZBURGER) { |_,_| true }
    action_for yes_button, KAXPressAction
  end

  def test_unregistering_noops_if_not_registered
    assert_block do
      AX.unregister_notifs
      AX.unregister_notifs
      AX.unregister_notifs
    end
  end

  def test_unregistering_sets_ignore_to_true
    AX.register_for_notif(yes_button, CHEEZBURGER) { |_,_| true }
    refute AX.instance_variable_get(:@ignore_notifs)
    AX.unregister_notifs
    assert AX.instance_variable_get(:@ignore_notifs)
  end

  def test_listening_to_app_catches_everything
    got_callback   = false
    AX.register_for_notif(REF, KAXValueChangedNotification) do |_,_|
      got_callback = true
    end
    action_for radio_gaga, KAXPressAction
    AX.wait_for_notif(TIMEOUT)
    assert got_callback
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
    assert_equal PID, AX.pid_of_element(window)
  end

end
