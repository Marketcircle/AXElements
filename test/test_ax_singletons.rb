class TestAX < MiniTest::Unit::TestCase
  class << self
    def pid_for_app name
      apps = NSWorkspace.sharedWorkspace.runningApplications
      apps.find { |app| app.localizedName == name }.processIdentifier
    end
  end

  APPS         = NSWorkspace.sharedWorkspace.runningApplications
  DOCK_PID     = pid_for_app 'Dock'
  DOCK         = AXUIElementCreateApplication(DOCK_PID)
  FINDER_PID   = pid_for_app 'Finder'
  FINDER       = AXUIElementCreateApplication(FINDER_PID)

  # HACK! forgive me
  DOCK_LIST    = AX.attr_of_element(DOCK, KAXChildrenAttribute).first
  DOCK_APP     = DOCK_LIST.send(:attribute, KAXChildrenAttribute).first
  RAW_DOCK_APP = DOCK_APP.instance_variable_get(:@ref)

  def with_full_logging
    AX.log.level = Logger::DEBUG
    yield
    AX.log.level = Logger::WARN
  end
end

##
# AFAICT every accessibility object **MUST** have attributes, so
# there are no tests to check what happens when they do not exist.
class TestAXAttrsOfElement < TestAX
  def setup; @attrs = AX.attrs_of_element(DOCK); end
  def test_returns_array_of_strings
    assert_instance_of String, @attrs.first
  end
  def test_make_sure_certain_attributes_are_present
    assert @attrs.include?(KAXRoleAttribute)
    assert @attrs.include?(KAXRoleDescriptionAttribute)
  end
  def test_other_attributes_that_the_dock_should_have
    assert @attrs.include?(KAXChildrenAttribute)
    assert @attrs.include?(KAXTitleAttribute)
  end
end

class TestAXAttrOfElement < TestAX
  def test_does_not_return_raw_values
    assert_kind_of AX::Element, AX.attr_of_element(FINDER, KAXMenuBarAttribute)
  end
  def test_does_not_return_raw_values_in_array
    ret = AX.attr_of_element(DOCK, KAXChildrenAttribute).first
    assert_kind_of AX::Element, ret
  end

  def test_returns_nil_for_non_existant_attributes
    assert_nil AX.attr_of_element(DOCK, 'MADEUPATTRIBUTE')
  end
  def test_logs_message_for_non_existant_attributes
    with_full_logging do AX.attr_of_element(DOCK, 'MADEUPATTRIBUTE') end
    assert_match /#{KAXErrorAttributeUnsupported}/, @log_output.string
  end

  def test_returns_nil_for_nil_attributes
    assert_nil AX.attr_of_element(DOCK, KAXFocusedUIElementAttribute)
  end

  def test_returns_boolean_false_for_false_attributes
    assert_equal false, AX.attr_of_element(DOCK, 'AXEnhancedUserInterface')
  end

  # @todo have to go deep to find a reliably true attribute
  # def test_returns_boolean_true_for_true_attributes
  # end

  def test_wraps_axuielementref_objects
    ret = AX.attr_of_element(FINDER, KAXMenuBarAttribute)
    assert_instance_of AX::MenuBar, ret
  end

  def test_returns_array_for_array_attributes
    ret = AX.attr_of_element(DOCK, KAXChildrenAttribute)
    assert_kind_of Array, ret
  end
  def test_returned_arrays_are_not_empty_when_they_should_have_stuff
    refute_empty AX.attr_of_element(DOCK, KAXChildrenAttribute)
  end

  # @todo have to go deep to find a reliable number attribute,
  #       dock separators have number value for thier AXValueAttribute
  # def test_returns_number_for_number_attribute
  # end

  # @todo I have no idea where to find an attribute that has this type
  # def test_returns_array_of_numbers_when_attribute_has_an_array_of_numbers
  # end

  def test_returns_a_cgsize_for_size_attributes
    mb = AX.attr_of_element(FINDER, KAXMenuBarAttribute)
    assert_instance_of CGSize, mb.get_attribute(:size)
  end

  def test_returns_a_cgpoint_for_point_attributes
    mb = AX.attr_of_element(FINDER, KAXMenuBarAttribute)
    assert_instance_of CGPoint, mb.get_attribute(:position)
  end

  # @todo have to go deep to find a reliable source of ranges
  # def test_returns_a_cfrage_for_range_attributes
  # end

  # @todo not sure where I can find a rect easily
  # def test_returns_a_cgrect_for_rect_attributes
  # end

  def test_works_with_strings
    assert_kind_of NSString, AX.attr_of_element(DOCK, KAXTitleAttribute)
  end
end

class TestAXElementAttributeWritable < TestAX
  def test_true_for_writable_attribute
    assert AX.attr_of_element_writable?(RAW_DOCK_APP, KAXSelectedAttribute)
  end
  def test_false_for_non_writable_attribute
    refute AX.attr_of_element_writable?(DOCK, KAXTitleAttribute)
  end
  def test_false_for_non_existante_attribute
    refute AX.attr_of_element_writable?(DOCK, 'FAKE')
  end
  # # @todo this test fails because I am not getting the expected result code
  # def test_logs_errors
  #   with_full_logging do AX.attr_of_element_writable?(DOCK, 'OMG') end
  #   assert_match /#{KAXErrorAttributeUnsupported}/, @log_output.string
  # end
end

class TestAXSetAttrOfElement < TestAX
  # @todo these tests require me to go deep into a UI
  # def test_set_a_text_fields_value
  # end
  # def test_set_a_radio_button
  # end
end

class TestAXActionsOfElement < TestAX
  def test_works_when_there_are_no_actions
    assert_empty AX.actions_of_element(DOCK)
  end
  def test_returns_array_of_strings
    assert_instance_of String, AX.actions_of_element(RAW_DOCK_APP).first
  end
  def test_make_sure_certain_actions_are_present
    actions = AX.actions_of_element(RAW_DOCK_APP)
    assert actions.include?(KAXPressAction)
    assert actions.include?(KAXShowMenuAction)
  end
end

class TestAXPerformActionOfElement < TestAX
  def dock_kids
    AX.attr_of_element(RAW_DOCK_APP, KAXChildrenAttribute)
  end

  def test_performs_an_action
    before_action_kid_count = dock_kids.count
    AX.perform_action_of_element(RAW_DOCK_APP, KAXShowMenuAction)
    assert dock_kids.count > before_action_kid_count
  end
end

# # @todo these need to go pretty deep
# class TestAXPostKBString < TestAX
#   def test_post_to_system
#   end
#   def test_post_to_finder
#   end
# end

# # @todo things with parameterized attributes are deep down
# class TestAXParamAttrsOfElement < TestAX
# end
# class TestAXParamAttrOfElement < TestAX
# end

# @todo this is totally broken right now
# class TestAXWaitForNotification < TestAX
#   def test_wait_for_finder_prefs
#     got_notification = false
#     AX::FINDER.show_about_window
#     AX.wait_for_notification(FINDER, KAXWindowCreatedNotification, 1.0) {
#       |element, notif|
#       got_notification = true if element.is_a?('AX::StandardWindow')
#     }
#     assert got_notification
#   end
#   def test_waits_the_given_timeout
#   end
# end

class TestAXElementUnderMouse < MiniTest::Unit::TestCase
  def test_returns_some_kind_of_ax_element
    assert_kind_of AX::Element, AX.element_under_mouse
  end
  # @todo need to manipulate the mouse and put it in some
  #       well known locations and make sure I get the right
  #       element created
end

class TestAXElementAtPosition < MiniTest::Unit::TestCase
  def test_returns_a_menubar_for_coordinates_10_0
    item = AX.element_at_position( CGPoint.new(10, 0) )
    assert_instance_of AX::MenuBarItem, item
  end
end

class TestAXHierarchy < TestAX
  RET = AX.hierarchy( DOCK_APP )
  def test_returns_array_of_elements
    assert_instance_of Array, RET
    assert_kind_of     AX::Element, RET.first
  end
  def test_correctness
    assert_equal 3, RET.size
    assert_instance_of AX::ApplicationDockItem, RET.first
    assert_instance_of AX::List,                RET.second
    assert_instance_of AX::Application,         RET.third
  end
end

class TestAXApplicationForPID < TestAX
  def test_makes_an_app
    assert_instance_of AX::Application, AX.application_for_pid(FINDER_PID)
  end
end

class TestAXApplicationForBundleIdentifier < TestAX
  BUNDLE_ID = 'com.apple.systemuiserver'
  def test_makes_an_app
    ret = AX.application_for_bundle_identifier(BUNDLE_ID, 0)
    assert_instance_of AX::Application, ret
  end
end

class TestAXPIDOfElement < TestAX
  def test_pid_of_app
    assert_equal FINDER_PID, AX.pid_of_element(FINDER)
  end
  def test_pid_of_dock_app_is_docks_pid
    assert_equal DOCK_PID, AX.pid_of_element(RAW_DOCK_APP)
  end
end

class TestAXLogAXCall < TestAX
  def test_code_is_returned
    assert_equal KAXErrorIllegalArgument, AX.send(:log_ax_call, DOCK, KAXErrorIllegalArgument)
    assert_equal KAXErrorAPIDisabled, AX.send(:log_ax_call, DOCK, KAXErrorAPIDisabled)
    assert_equal KAXErrorSuccess, AX.send(:log_ax_call, DOCK, KAXErrorSuccess)
  end
  def test_logs_nothing_for_success_case
    with_full_logging { AX.send(:log_ax_call, DOCK, KAXErrorSuccess) }
    assert_empty @log_output.string
  end
  def test_looks_up_code_properly
    with_full_logging { AX.send(:log_ax_call, DOCK, KAXErrorAPIDisabled) }
    assert_match /API Disabled/, @log_output.string
    with_full_logging { AX.send(:log_ax_call, DOCK, KAXErrorNotImplemented) }
    assert_match /Not Implemented/, @log_output.string
  end
end
