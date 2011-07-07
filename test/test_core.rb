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

  def static_text
    @@static_text ||= child KAXStaticTextRole
  end

  def search_box
    @@search_box ||= child KAXTextFieldRole
  end

  def button
    @@button ||= child KAXButtonRole
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
# there are no tests to check what happens when they do not exist.
class TestAttrsOfElement < TestCore

  def attrs
    @@attrs ||= AX.attrs_of_element(REF)
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


class TestAttrOfElementGetsCorrectAttribute < TestCore

  def test_title_is_title
    assert_equal 'AXElementsTester', AX.attr_of_element(REF, KAXTitleAttribute)
  end

  # @todo the app gives CGRectZero in Cocoa coordinates, and then they are
  #       flipped for us to carbon, so we need to flip them again
  def test_custom_lol_is_rect
    expected_rect = CGRect.new(CGPointZero.dup.carbonize!, CGSizeZero)
    assert_equal expected_rect, AX.attr_of_element(WINDOW, 'AXLol')
  end

  def test_hidden_is_boolean
    assert_equal false, AX.attr_of_element(REF, KAXHiddenAttribute)
  end

end


class TestAttrOfElementParsesData < TestCore

  def test_does_not_return_raw_values
    assert_kind_of AX::Element, AX.attr_of_element(REF, KAXMenuBarAttribute)
  end

  def test_does_not_return_raw_values_in_array
    assert_kind_of AX::Element, AX.attr_of_element(REF, KAXChildrenAttribute).first
  end

  def test_returns_nil_for_non_existant_attributes
    assert_nil AX.attr_of_element(REF, 'MADEUPATTRIBUTE')
  end

  def test_returns_nil_for_nil_attributes
    assert_nil AX.attr_of_element(WINDOW, KAXProxyAttribute)
  end

  def test_returns_boolean_false_for_false_attributes
    assert_equal false, AX.attr_of_element(REF, 'AXEnhancedUserInterface')
  end

  def test_returns_boolean_true_for_true_attributes
    assert_equal true, AX.attr_of_element(WINDOW, KAXMainAttribute)
  end

  def test_wraps_axuielementref_objects
    # need intermediate step to make sure AX::MenuBar exists
    ret = AX.attr_of_element(REF, KAXMenuBarAttribute)
    assert_instance_of AX::MenuBar, ret
  end

  def test_returns_array_for_array_attributes
    assert_kind_of Array, AX.attr_of_element(REF, KAXChildrenAttribute)
  end

  def test_returned_arrays_are_not_empty_when_they_should_have_stuff
    refute_empty AX.attr_of_element(REF, KAXChildrenAttribute)
  end

  def test_returned_element_arrays_do_not_have_raw_elements
    assert_kind_of AX::Element, AX.attr_of_element(REF, KAXChildrenAttribute).first
  end

  def test_returns_number_for_number_attribute
    assert_instance_of Fixnum, AX.attr_of_element(check_box, KAXValueAttribute)
  end

  def test_returns_array_of_numbers_when_attribute_has_an_array_of_numbers
    # could be a float or a fixnum, be more lenient
    assert_kind_of NSNumber, AX.attr_of_element(slider, KAXAllowedValuesAttribute).first
  end

  def test_returns_a_cgsize_for_size_attributes
    assert_instance_of CGSize, AX.attr_of_element(WINDOW, KAXSizeAttribute)
  end

  def test_returns_a_cgpoint_for_point_attributes
    assert_instance_of CGPoint, AX.attr_of_element(WINDOW, KAXPositionAttribute)
  end

  def test_returns_a_cfrange_for_range_attributes
    assert_instance_of CFRange, AX.attr_of_element(static_text, KAXVisibleCharacterRangeAttribute)
  end

  def test_returns_a_cgrect_for_rect_attributes
    assert_kind_of CGRect, AX.attr_of_element(WINDOW, 'AXLol')
  end

  def test_works_with_strings
    assert_instance_of String, AX.attr_of_element(REF, KAXTitleAttribute)
  end

  def test_works_with_urls
    assert_instance_of NSURL, AX.attr_of_element(WINDOW, KAXURLAttribute)
  end

end


class TestAttrOfElementErrors < TestCore
  include LoggingCapture

  def test_logs_message_for_non_existant_attributes
    with_logging do AX.attr_of_element(REF, 'MADEUPATTRIBUTE') end
    assert_match /#{KAXErrorAttributeUnsupported}/, @log_output.string
  end

end


class TestAttrOfElementChoosesCorrectClasseForElements < TestCore

  def test_chooses_role_if_no_subrole
    assert_instance_of AX::Application, AX.attr_of_element(WINDOW, KAXParentAttribute)
  end

  def test_chooses_subrole_if_it_exists
    classes = AX.attr_of_element(WINDOW, KAXChildrenAttribute).map(&:class)
    assert_includes classes, AX::CloseButton
    assert_includes classes, AX::SearchField
  end

  def test_chooses_role_if_subrole_is_nil
    scroll_area = child KAXScrollAreaRole
    web_area    = AX.attr_of_element(scroll_area, KAXChildrenAttribute).first
    assert_instance_of AX::WebArea, web_area
  end

  # we use dock items here, because this is an easy case of
  # the role class being recursively created when trying to
  # create the subrole class
  def test_creates_role_for_subrole_if_it_does_not_exist_yet
    dock     = AXUIElementCreateApplication(pid_for 'com.apple.dock')
    list     = children_for(dock).first
    children = AX.attr_of_element(list, KAXChildrenAttribute).map(&:class)
    assert_includes children, AX::ApplicationDockItem
  end

  # @todo this happens when accessibility is not implemented correctly,
  #       and the problem with fixing it is the performance cost
  def test_chooses_role_if_subrole_is_unknown_type
    skip 'This case is not handled right now'
  end

  def test_creates_inheritance_chain
    assert_equal AX::Button, AX::CloseButton.superclass
    assert_equal AX::Element, AX::Button.superclass
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

  def test_logs_errors
    skip 'test fails because we are not getting the expected result code'
    with_logging do AX.attr_of_element_writable?(DOCK, 'OMG') end
    assert_match /#{KAXErrorAttributeUnsupported}/, @log_output.string
  end

end


class TestSetAttrOfElement < TestCore

  def test_set_a_slider
    [25, 75, 50].each do |value|
      AX.set_attr_of_element(slider, KAXValueAttribute, value)
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
    assert_empty AX.actions_of_element(REF)
  end

  def test_returns_array_of_strings
    assert_instance_of String, AX.actions_of_element(yes_button).first
  end

  def test_make_sure_certain_actions_are_present
    actions = AX.actions_of_element(slider)
    assert_includes actions, KAXIncrementAction
    assert_includes actions, KAXDecrementAction
  end

end


class TestActionOfElement < TestCore

  def test_check_a_check_box
    2.times do # twice so it should be back where it started
      value = value_for(check_box)
      AX.action_of_element(check_box, KAXPressAction)
      refute_equal value, value_for(check_box)
    end
  end

  def test_sliding_the_slider
    value = attribute_for(slider, KAXValueAttribute)
    AX.action_of_element(slider, KAXIncrementAction)
    assert attribute_for(slider, KAXValueAttribute) > value

    value = attribute_for(slider, KAXValueAttribute)
    AX.action_of_element(slider, KAXDecrementAction)
    assert attribute_for(slider, KAXValueAttribute) < value
  end

end


# @todo As soon as I add the new mapping thing
# class TestKeyboardAction < TestCore

#   SYSTEM = AXUIElementCreateSystemWide()

#   def post_to_system string
#     spotlight_text_field do |field|
#       AX.keyboard_action(SYSTEM, string)
#       sleep 0.01
#       assert_equal string, attribute_for( field, KAXValueAttribute )
#     end
#   end

#   def test_uppercase_letters
#     post_to_system 'HELLO, WORLD'
#   end

#   def test_numbers
#     post_to_system '42'
#   end

#   def test_letters
#     post_to_system 'the cake is a lie'
#   end

#   def test_escape_sequences
#     post_to_system "\s"
#   end

# end


# @todo I haven't really gotten around to using the parameterized
#       attributes code, and am working out some details, so I do
#       not have regression tests yet

# class TestAXParamAttrsOfElement < TestCore
# end

# class TestAXParamAttrOfElement < TestCore
# end


class TestAXNotifications < TestCore

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

  def short_timeout
    0.1
  end

  def timeout
    1.0
  end

  def teardown
    if attribute_for(radio_gaga, KAXValueAttribute) == 1
      action_for radio_flyer, KAXPressAction
    end
  end

  # this test is weird, sometimes the radio group sends the notification
  # first and other times the button sends it, but for the sake of the
  # test we only care that one of them sent the notif
  def test_yielded_proper_objects
    element = notification = nil
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) do |el,notif|
      element, notification = el, notif
    end

    action_for radio_gaga, KAXPressAction

    assert AX.wait_for_notif(1.0)
    assert_kind_of NSString, notification
    assert_includes ['AX::RadioButton', 'AX::RadioGroup'], element.class.to_s
  end

  def test_works_without_a_block
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification)
    start = Time.now
    action_for radio_gaga, KAXPressAction

    AX.wait_for_notif(timeout)
    assert_in_delta Time.now, start, timeout
  end

  def test_follows_block_return_value_when_false
    got_callback   = false
    AX.register_for_notif(radio_gaga, KAXValueChangedNotification) do |_,_|
      got_callback = true
      false
    end
    action_for radio_gaga, KAXPressAction

    start = Time.now
    AX.wait_for_notif(short_timeout)
    refute_in_delta Time.now, start, short_timeout
  end

  def test_waits_the_given_timeout
    start = Time.now
    refute AX.wait_for_notif(short_timeout), 'Failed to wait'
    assert_in_delta (Time.now - start), short_timeout, 0.05
  end

  def test_listening_to_app_catches_everything
    got_callback   = false
    AX.register_for_notif(REF, KAXValueChangedNotification) do |el, notif|
      got_callback = true
    end
    action_for radio_gaga, KAXPressAction
    AX.wait_for_notif(timeout)
    assert got_callback
  end

  def test_works_with_custom_notifications
    got_callback = false
    button = yes_button
    AX.register_for_notif(yes_button, 'Cheezburger') do |_,_|
      got_callback = true
    end
    action_for yes_button, KAXPressAction
    AX.wait_for_notif(timeout)
    assert got_callback
  end

  # not the block you gave, it returns one it creates
  # which is actually a wrapper for the block given
  def test_returns_the_callback_proc
    callback = AX.register_for_notif(yes_button, 'Cheezburger') do |_,_| end
    assert_equal 4, callback.arity
  end

  def test_callbacks_are_unregistered_when_a_timeout_occurs
    skip 'This feature is not implemented yet'
  end

end


class TestElementAtPosition < TestCore

  def test_returns_a_button_when_i_give_the_coordinates_of_a_button
    point = attribute_for(button, KAXPositionAttribute)
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(point, KAXValueCGPointType, ptr)
    point = ptr[0]
    element = AX.element_at_point(*point.to_a)
    assert_equal button, element.ref
  end

end


class TestApplicationForPID < TestCore

  def test_makes_an_app
    assert_instance_of AX::Application, AX.application_for_pid(PID)
  end

  # invalid pid will crash MacRuby, so we don't bother testing it

end


class TestPIDOfElement < TestCore

  def test_pid_of_app
    assert_equal PID, AX.pid_of_element(REF)
  end

  def test_pid_of_dock_app_is_docks_pid
    assert_equal PID, AX.pid_of_element(WINDOW)
  end

end


class TestStripPrefix < MiniTest::Unit::TestCase

  def prefix_test before, after
    assert_equal after, AX.strip_prefix(before)
  end

  def test_removes_ax_prefix
    prefix_test 'AXButton', 'Button'
  end

  def test_removes_combination_prefixes
    prefix_test 'MCAXButton', 'Button'
  end

  def test_works_with_all_caps
    prefix_test 'AXURL', 'URL'
  end

  def test_works_with_long_name
    prefix_test 'AXTitleUIElement', 'TitleUIElement'
  end

  def test_strips_predicate_too
    prefix_test 'AXIsApplicationRunning', 'ApplicationRunning'
  end

  def test_is_not_greedy
    prefix_test 'AXAX', 'AX'
  end

end


# I'd prefer to not to be directly calling the log method bypassing
# the fact that it is a private method
class TestLogAXCall < TestCore
  include LoggingCapture

  def test_looks_up_code_properly
    with_logging { AX.send(:log_error, APP, KAXErrorAPIDisabled) }
    assert_match /API Disabled/, @log_output.string
    with_logging { AX.send(:log_error, APP, KAXErrorNotImplemented) }
    assert_match /Not Implemented/, @log_output.string
  end

  def test_handles_unknown_error_codes
    with_logging { AX.send(:log_error, APP, 1234567) }
    assert_match /UNKNOWN ERROR CODE/, @log_output.string
  end

  def test_logs_debug_info
    skip 'TODO, low priority until someone wants to change the code'
  end

end
