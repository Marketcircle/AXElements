module CoreHelpers

  def pid_for name
    NSWorkspace.sharedWorkspace.runningApplications.find do |app|
      app.bundleIdentifier == name
    end.processIdentifier
  end

  # returns raw attribute
  def attribute_for element, attr
    ptr = Pointer.new :id
    AXUIElementCopyAttributeValue(element, attr, ptr)
    ptr[0]
  end

  def children_for element
    attribute_for element, KAXChildrenAttribute
  end

  def value_for element
    attribute_for element, KAXValueAttribute
  end

  def element_at point
    ptr    = Pointer.new '^{__AXUIElement}'
    system = AXUIElementCreateSystemWide()
    AXUIElementCopyElementAtPosition(system, point.x, point.y, ptr)
    ptr[0]
  end

end


class TestCore < TestAX
  include CoreHelpers
  extend  CoreHelpers

  APP_PID = pid_for APP_BUNDLE_IDENTIFIER
  APP     = AXUIElementCreateApplication(APP_PID)
  WINDOW  = attribute_for APP, KAXMainWindowAttribute
end


##
# AFAICT every accessibility object **MUST** have attributes, so
# there are no tests to check what happens when they do not exist.
class TestAttrsOfElement < TestCore

  def setup
    @attrs = AX.attrs_of_element(APP)
  end

  def test_returns_array_of_strings
    assert_instance_of String, @attrs.first
  end

  def test_make_sure_certain_attributes_are_provided
    assert_includes @attrs, KAXRoleAttribute
    assert_includes @attrs, KAXRoleDescriptionAttribute
  end

  def test_other_attributes_that_the_app_should_have
    assert_includes @attrs, KAXChildrenAttribute
    assert_includes @attrs, KAXTitleAttribute
    assert_includes @attrs, KAXMenuBarAttribute
  end

end


class TestAttrOfElementGetsCorrectAttribute < TestCore

  def test_title
    assert_equal 'AXElementsTester', AX.attr_of_element(APP, KAXTitleAttribute)
  end

  # @todo the app gives CGRectZero in Cocoa coordinates, and then they are
  #       flipped, so we need to flip it again
  def test_custom_lol
    expected_rect = CGRect.new(CGPointZero.dup.carbonize!, CGSizeZero)
    assert_equal expected_rect, AX.attr_of_element(WINDOW, 'AXLol')
  end

  def test_hidden
    assert_equal false, AX.attr_of_element(APP, KAXHiddenAttribute)
  end

end


class TestAttrOfElementParsesData < TestCore

  def test_does_not_return_raw_values
    assert_kind_of AX::Element, AX.attr_of_element(APP, KAXMenuBarAttribute)
  end

  def test_does_not_return_raw_values_in_array
    assert_kind_of AX::Element, AX.attr_of_element(APP, KAXChildrenAttribute).first
  end

  def test_returns_nil_for_non_existant_attributes
    assert_nil AX.attr_of_element(APP, 'MADEUPATTRIBUTE')
  end

  def test_returns_nil_for_nil_attributes
    assert_nil AX.attr_of_element(WINDOW, KAXProxyAttribute)
  end

  def test_returns_boolean_false_for_false_attributes
    assert_equal false, AX.attr_of_element(APP, 'AXEnhancedUserInterface')
  end

  def test_returns_boolean_true_for_true_attributes
    ret = AX.attr_of_element(WINDOW, KAXMainAttribute)
    assert_equal true, ret
  end

  def test_wraps_axuielementref_objects
    ret = AX.attr_of_element(APP, KAXMenuBarAttribute)
    assert_instance_of AX::MenuBar, ret
  end

  def test_returns_array_for_array_attributes
    assert_kind_of Array, AX.attr_of_element(APP, KAXChildrenAttribute)
  end

  def test_returned_arrays_are_not_empty_when_they_should_have_stuff
    refute_empty AX.attr_of_element(APP, KAXChildrenAttribute)
  end

  def test_returned_element_arrays_do_not_have_raw_elements
    assert_kind_of AX::Element, AX.attr_of_element(APP, KAXChildrenAttribute).first
  end

  def test_returns_number_for_number_attribute
    box = children_for( WINDOW ).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXCheckBoxRole
    end
    assert_instance_of Fixnum, AX.attr_of_element(box, KAXValueAttribute)
  end

  def test_returns_array_of_numbers_when_attribute_has_an_array_of_numbers
    slider = children_for( WINDOW ).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXSliderRole
    end
    ret = AX.attr_of_element(slider, KAXAllowedValuesAttribute)
    assert_kind_of NSNumber, ret.first
  end

  def test_returns_a_cgsize_for_size_attributes
    assert_instance_of CGSize, AX.attr_of_element(WINDOW, KAXSizeAttribute)
  end

  def test_returns_a_cgpoint_for_point_attributes
    assert_instance_of CGPoint, AX.attr_of_element(WINDOW, KAXPositionAttribute)
  end

  def test_returns_a_cfrange_for_range_attributes
    text = children_for( WINDOW ).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXStaticTextRole
    end
    assert_instance_of CFRange, AX.attr_of_element(text, KAXVisibleCharacterRangeAttribute)
  end

  def test_returns_a_cgrect_for_rect_attributes
    assert_kind_of CGRect, AX.attr_of_element(WINDOW, 'AXLol')
  end

  def test_works_with_strings
    assert_instance_of String, AX.attr_of_element(APP, KAXTitleAttribute)
  end

  def test_works_with_urls
    assert_instance_of NSURL, AX.attr_of_element(WINDOW, KAXURLAttribute)
  end

end


class TestAttrOfElementErrors < TestCore
  include LoggingCapture

  def test_logs_message_for_non_existant_attributes
    with_logging do AX.attr_of_element(APP, 'MADEUPATTRIBUTE') end
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
    scroll_area = children_for(WINDOW).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXScrollAreaRole
    end
    web_area = AX.attr_of_element(scroll_area, KAXChildrenAttribute).first
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

  # @todo find out if this only happens with windows or if it happens
  #       with every type that must have a subrole but does not supply
  #       one
  def test_chooses_role_if_subrole_is_unknown_type
    skip 'This case is not handled right now'
  end

end


class TestAttrOfElementSubclassesProperly < TestCore

  def test_creates_inheritance_chain
    assert_includes AX::CloseButton.ancestors, AX::Button
  end

end


class TestElementAttributeWritable < TestCore

  def test_true_for_writable_attribute
    assert AX.attr_of_element_writable?(WINDOW, KAXMainAttribute)
  end

  def test_false_for_non_writable_attribute
    refute AX.attr_of_element_writable?(APP, KAXTitleAttribute)
  end

  def test_false_for_non_existante_attribute
    refute AX.attr_of_element_writable?(APP, 'FAKE')
  end

  # # @todo this test fails because I am not getting the expected result code
  # def test_logs_errors
  #   with_logging do AX.attr_of_element_writable?(DOCK, 'OMG') end
  #   assert_match /#{KAXErrorAttributeUnsupported}/, @log_output.string
  # end

end


class TestSetAttrOfElement < TestCore

  def test_set_a_slider
    slider = children_for( WINDOW ).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXSliderRole
    end
    [25, 75, 50].each do |value|
      AX.set_attr_of_element(slider, KAXValueAttribute, value)
      assert_equal value, value_for(slider)
    end
  end

  def test_set_a_text_field
    check_box = children_for( WINDOW ).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXTextFieldRole
    end
    [Time.now.to_s, ''].each do |value|
      AX.set_attr_of_element(check_box, KAXValueAttribute, value)
      assert_equal value, value_for(check_box)
    end
  end

end


class TestActionsOfElement < TestCore

  def test_works_when_there_are_no_actions
    assert_empty AX.actions_of_element(APP)
  end

  def test_returns_array_of_strings
    button = children_for(WINDOW).find do |item|
      attribute_for(item,KAXRoleAttribute) == KAXButtonRole
    end
    assert_instance_of String, AX.actions_of_element(button).first
  end

  def test_make_sure_certain_actions_are_present
    slider = children_for(WINDOW).find do |item|
      attribute_for(item,KAXRoleAttribute) == KAXSliderRole
    end
    actions = AX.actions_of_element(slider)
    assert_includes actions, KAXIncrementAction
    assert_includes actions, KAXDecrementAction
  end

end


class TestActionOfElement < TestCore

  def test_check_a_check_box
    check_box = children_for( WINDOW ).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXCheckBoxRole
    end
    2.times do # twice so it should be back where it started
      value = value_for(check_box)
      AX.action_of_element(check_box, KAXPressAction)
      refute_equal value, value_for(check_box)
    end
  end

  def test_sliding_the_slider
    slider = children_for(WINDOW).find do |item|
      attribute_for(item,KAXRoleAttribute) == KAXSliderRole
    end

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

  RADIO_GROUP = children_for(WINDOW).find do |item|
    attribute_for(item, KAXRoleAttribute) == KAXRadioGroupRole
  end

  RADIO_RADIO = children_for(RADIO_GROUP).find do |item|
    attribute_for(item, KAXTitleAttribute) == 'Radio'
  end

  RADIO_GAGA = children_for(RADIO_GROUP).find do |item|
    attribute_for(item, KAXTitleAttribute) == 'Gaga'
  end

  def action_for element, action
    AXUIElementPerformAction(element, action)
  end

  def set_attr_for element, attr, value
    AXUIElementSetAttributeValue(element, attr, value)
  end

  def menu_for button
    children_for(button).first
  end

  def short_timeout
    0.2
  end

  def timeout
    1.0
  end

  def teardown
    if attribute_for(RADIO_GAGA, KAXValueAttribute) == 1
      action_for RADIO_RADIO, KAXPressAction
    end
  end

  def test_yielded_proper_objects
    element = notification = nil
    AX.register_for_notif(RADIO_GAGA, KAXValueChangedNotification) do |el,notif|
      element, notification = el, notif
    end

    action_for RADIO_GAGA, KAXPressAction

    assert AX.wait_for_notif(1.0)
    assert_kind_of AX::RadioButton, element
    assert_kind_of NSString, notification
  end

  def test_works_without_a_block
    AX.register_for_notif(RADIO_GAGA, KAXValueChangedNotification)
    start = Time.now
    action_for RADIO_GAGA, KAXPressAction

    AX.wait_for_notif(timeout)
    assert_in_delta Time.now, start, timeout
  end

  def test_follows_block_return_value_when_false
    got_callback   = false
    AX.register_for_notif(RADIO_GAGA, KAXValueChangedNotification) do |_,_|
      got_callback = true
      false
    end
    action_for RADIO_GAGA, KAXPressAction

    start = Time.now
    AX.wait_for_notif(short_timeout)
    refute_in_delta Time.now, start, short_timeout
  end

  def test_waits_the_given_timeout
    start = Time.now
    AX.wait_for_notif(short_timeout)
    assert_in_delta (Time.now - start), short_timeout, 0.05
  end

  def test_listening_to_app_catches_everything
    got_callback   = false
    AX.register_for_notif(APP, KAXValueChangedNotification) do |el, notif|
      got_callback = true
    end
    action_for RADIO_GAGA, KAXPressAction
    AX.wait_for_notif(timeout)
    assert got_callback
  end

  def test_works_with_custom_notifications
    got_callback = false
    button = children_for(WINDOW).find do |item|
      if attribute_for(item, KAXRoleAttribute) == KAXButtonRole
        attribute_for(item, KAXTitleAttribute) == 'Yes'
      end
    end
    AX.register_for_notif(button, 'Cheezburger') do |_,_|
      got_callback = true
    end
    action_for button, KAXPressAction
    AX.wait_for_notif(timeout)
    assert got_callback
  end

  def test_callbacks_are_unregistered_when_a_timeout_occurs
    skip 'This feature is not implemented yet'
  end

end


class TestElementAtPosition < TestCore

  def test_returns_a_button_when_i_give_the_coordinates_of_a_button
    button = children_for(WINDOW).find do |item|
      attribute_for(item, KAXRoleAttribute) == KAXButtonRole
    end
    point = attribute_for(button, KAXPositionAttribute)
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(point, KAXValueCGPointType, ptr)
    point = ptr[0]
    element = AX.element_at_point(*point.to_a)
    assert_equal button, element.instance_variable_get(:@ref)
  end

end


class TestApplicationForPID < TestCore

  def test_makes_an_app
    assert_instance_of AX::Application, AX.application_for_pid(APP_PID)
  end

  # invalid pid will crash MacRuby, so we don't bother
  # testing it

end


class TestPIDOfElement < TestCore

  def test_pid_of_app
    assert_equal APP_PID, AX.pid_of_element(APP)
  end

  def test_pid_of_dock_app_is_docks_pid
    assert_equal APP_PID, AX.pid_of_element(WINDOW)
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
    skip 'TODO'
  end

end
