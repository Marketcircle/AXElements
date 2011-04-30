class TestElementAttributes < TestElements

  def test_not_empty
    refute_empty EL_DOCK.attributes
  end

  def test_contains_proper_info
    assert EL_DOCK.attributes.include?(KAXRoleAttribute)
    assert EL_DOCK.attributes.include?(KAXTitleAttribute)
  end

end


class TestElementGetAttribute < TestElements

  def test_raises_arg_error_for_non_existent_attributes
    assert_raises ArgumentError do EL_DOCK.get_attribute('fakeattribute') end
    assert_raises ArgumentError do EL_DOCK.get_attribute(:fakeattribute) end
  end

  def test_matches_single_word_attribute
    assert_equal KAXApplicationRole, EL_DOCK.get_attribute( :role )
  end

  def test_matches_mutlti_word_attribute
    assert_equal 'application', EL_DOCK.get_attribute( :role_description )
  end

  def test_matches_acronym_attributes
    assert_instance_of NSURL, EL_DOCK_APP.get_attribute(:url)
  end

  def test_is_predicate_matches
    assert_instance_of_boolean EL_DOCK_APP.get_attribute(:application_running?)
  end

  def test_non_is_predicates_match
    assert_instance_of_boolean EL_DOCK_APP.get_attribute(:selected?)
  end

  def test_gets_exact_match_except_prefix
    # finds role when role and subrole exist
    assert_equal 'Dock', EL_DOCK.get_attribute(:title)

    # finds top_level_ui_element and shown_menu_ui_element exists
    top_level  = EL_DOCK_APP.get_attribute(:top_level_ui_element)
    shown_menu = EL_DOCK_APP.get_attribute(:shown_menu_ui_element)
    refute_equal top_level, shown_menu
    assert_instance_of AX::List, top_level
    assert_nil shown_menu
  end

end



class TestElementDescription < TestElements

  def test_raise_error_if_object_has_no_description
    assert_raises ArgumentError do EL_DOCK.description end
  end

  def test_gets_description_if_object_has_a_description
    element = AX.element_at_position(
      CGPoint.new(NSScreen.mainScreen.frame.size.width - 10, 10)
                                     )
    assert_equal 'spotlight menu', element.description
  end

end


class TestElementPID < TestElements

  def test_actually_works
    assert_instance_of Fixnum, EL_DOCK_APP.pid
    refute EL_DOCK_APP.pid == 0
  end

end


class TestElementAttribute < TestElements

  def test_actually_works
    assert_equal 'Dock', EL_DOCK.attribute(KAXTitleAttribute)
  end

end


class TestElementAttributeWritable < TestElements

  def test_raises_error_for_non_existant_attributes
    assert_raises ArgumentError do
      EL_DOCK.attribute_writable?(:fake_attribute)
    end
  end

  def test_true_for_writable_attributes
    assert EL_DOCK_APP.attribute_writable? :selected
  end

  def test_false_for_non_writable_attributes
    refute EL_DOCK.attribute_writable? :title
  end

end


class TestElementSetAttribute < TestElements

  def test_set_a_text_fields_value
    spotlight_text_field do |field|
      new_value = "#{Time.now}"
      item = AX::Element.new(field)
      item.set_attribute( :value, new_value )
      assert_equal new_value, attribute_for( field, KAXValueAttribute )
    end
  end

end


class TestElementAttributeEquals < TestElements

  def test_actually_works
    spotlight_text_field do |field|
      new_value = "#{Time.now}"
      item = AX::Element.new(field)
      item.send( :attribute=, KAXValueAttribute, new_value )
      assert_equal new_value, attribute_for( field, KAXValueAttribute )
    end
  end

end


# @todo implement missing test cases
class TestElementParamAttributes < TestElements

  def test_empty_for_dock
    assert_empty EL_DOCK.param_attributes
  end

  # def test_not_empty_for_something
  # end
  # def test_contains_proper_info
  # end
  # @todo some other tests copied from testing #get_attributes

end


# @todo I'll get to this when I need to get to parameterized attributes
class TestElementGetParamAttribute < TestElements

#   def test_returns_nil_for_non_existent_attributes
#   end
#   def test_fetches_attribute
#   end

end


class TestElementActions < TestElements

  def test_empty_for_dock
    assert_empty EL_DOCK.actions
  end

  def test_not_empty_for_dock_item
    refute_empty EL_DOCK_APP.actions
  end

  def test_contains_proper_info
    assert EL_DOCK_APP.actions.include?(KAXPressAction)
    assert EL_DOCK_APP.actions.include?(KAXShowMenuAction)
  end

end
