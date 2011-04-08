class TestAX < MiniTest::Unit::TestCase
  class << self
    def pid_for_app name
      apps = NSWorkspace.sharedWorkspace.runningApplications
      apps.find { |app| app.localizedName == name }.processIdentifier
    end
  end

  DOCK     = AXUIElementCreateApplication(pid_for_app 'Dock')
  FINDER   = AXUIElementCreateApplication(pid_for_app 'Finder')

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
    list = AX.attr_of_element(DOCK, KAXChildrenAttribute).first
    app  = list.get_attribute(:children).first
    ref  = app.instance_variable_get(:@ref) # HACK! forgive me
    assert AX.attr_of_element_writable?(ref, KAXSelectedAttribute)
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
  def test_
  end
end

# class TestAXPluralConstGet < MiniTest::Unit::TestCase
#   def test_finds_things_that_are_not_pluralized
#     refute_nil AX.plural_const_get( 'Application' )
#   end
#   def test_finds_things_that_are_pluralized_with_an_s
#     refute_nil AX.plural_const_get( 'Applications' )
#   end
#   def test_returns_nil_if_the_class_does_not_exist
#     assert_nil AX.plural_const_get( 'NonExistant' )
#   end
# end

class TestAXActionsOfElement < MiniTest::Unit::TestCase
  def test_works_when_there_are_no_actions
    assert_empty AX.actions_of_element(DOCK)
  end
  def test_returns_array_of_strings
    list = AX.raw_attr_of_element(DOCK,KAXChildrenAttribute).first
    app  = AX.raw_attr_of_element(list,KAXChildrenAttribute).first
    assert_instance_of String, AX.actions_of_element(app).first
  end
  def test_make_sure_certain_actions_are_present
    list = AX.raw_attr_of_element(DOCK,KAXChildrenAttribute).first
    app  = AX.raw_attr_of_element(list,KAXChildrenAttribute).first
    actions = AX.actions_of_element(app)
    assert actions.include?(KAXPressAction)
    assert actions.include?(KAXShowMenuAction)
  end
end

class TestAXLogAXCall < MiniTest::Unit::TestCase
  def setup; super; AX.log.level = Logger::DEBUG; end
  def teardown; AX.log.level = Logger::WARN; end
  def test_code_is_returned
    assert_equal KAXErrorIllegalArgument, AX.log_ax_call(DOCK, KAXErrorIllegalArgument)
    assert_equal KAXErrorAPIDisabled, AX.log_ax_call(DOCK, KAXErrorAPIDisabled)
    assert_equal KAXErrorSuccess, AX.log_ax_call(DOCK, KAXErrorSuccess)
  end
  def test_logs_nothing_for_success_case
    AX.log_ax_call(DOCK, KAXErrorSuccess)
    assert_empty @log_output.string
  end
  def test_looks_up_code_properly
    AX.log_ax_call(DOCK, KAXErrorAPIDisabled)
    assert_match /API Disabled/, @log_output.string
    AX.log_ax_call(DOCK, KAXErrorNotImplemented)
    assert_match /Not Implemented/, @log_output.string
  end
end
