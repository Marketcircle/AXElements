class TestElements < TestAX

  APP_PID = pid_for APP_BUNDLE_IDENTIFIER
  APP     = AX::Element.new(APP_REF)
  WINDOW  = AX.attr_of_element(APP_REF, KAXMainWindowAttribute)

  def window_children
    @@window_children ||= AX.attr_of_element(
                                             WINDOW.instance_variable_get(:@ref),
                                             KAXChildrenAttribute
                                             )
  end

  def no_button
    @@no_button ||= window_children.find do |item|
      item.class == AX::Button && item.attributes.include?(KAXDescriptionAttribute)
    end
  end

  def slider
    @@slider ||= window_children.find do |item|
      item.class == AX::Slider
    end
  end

  def value_for element
    ref = element.instance_variable_get(:@ref)
    AX.attr_of_element(ref, KAXValueAttribute)
  end

end


class TestElementLookupFailure < TestAX

  def test_kind_of_argument_error
    assert_kind_of ArgumentError, AX::Element::LookupFailure.new(:blah)
  end

  def test_correct_message
    exception = AX::Element::LookupFailure.new(:test)
    assert_match /was not found/, exception.message
  end

end


class TestElementAttributeReadOnly < TestAX

  def test_kind_of_method_missing_error
    assert_kind_of NoMethodError, AX::Element::AttributeReadOnly.new(:blah)
  end

  def test_correct_message
    exception = AX::Element::AttributeReadOnly.new(:test)
    assert_match /read only attribute/, exception.message
  end

end


class TestElementAttributes < TestElements

  def test_not_empty
    refute_empty APP.attributes
  end

  def test_contains_proper_info
    assert_includes APP.attributes, KAXRoleAttribute
    assert_includes APP.attributes, KAXTitleAttribute
  end

end


class TestElementGetAttribute < TestElements

  def test_raises_for_non_existent_attributes
    assert_raises AX::Element::LookupFailure do
      APP.attribute(:fakeattribute)
    end
  end

  def test_raises_if_cache_hit_but_object_does_not_have_attribute
    # make sure attr exists
    WINDOW.attribute :nyan?
    assert_raises AX::Element::LookupFailure do
      APP.attribute(:nyan?)
    end
  end

end


class TestElementGetAttributeTransformsSymbolToConstant < TestElements

  def test_matches_single_word_attribute
    assert_equal KAXApplicationRole, APP.attribute(:role)
  end

  def test_matches_mutlti_word_attribute
    assert_equal 'application', APP.attribute(:role_description)
  end

  def test_matches_acronym_attributes
    assert_instance_of NSURL, WINDOW.attribute(:url)
  end

  def test_predicate_that_starts_with_is
    assert_instance_of_boolean WINDOW.attribute(:nyan?)
  end

  def test_predicate_that_does_not_start_with_is
    assert_instance_of_boolean WINDOW.attribute(:focused?)
  end

  def test_matches_exactly_with_one_word
    # finds role when role and subrole exist
    assert_equal KAXStandardWindowSubrole, WINDOW.attribute(:subrole)
    assert_equal KAXWindowRole,            WINDOW.attribute(:role)
  end

  def test_matches_exactly_with_multiple_words
    assert_equal   'AXElementsTester', WINDOW.attribute(:title)
    assert_kind_of AX::Element,        WINDOW.attribute(:title_ui_element)
  end

end


class TestElementDescription < TestElements

  def test_raise_error_if_object_has_no_description
    assert_raises AX::Element::LookupFailure do APP.description end
  end

  def test_gets_description
    assert_equal 'The cake is a lie!', no_button.description
  end

end


class TestElementPID < TestElements

  def test_works_for_apps
    assert_kind_of NSNumber, APP.pid
    refute_equal 0, APP.pid
  end

  def test_works_for_aribtrary_elements
    assert_kind_of NSNumber, WINDOW.pid
    refute_equal 0, WINDOW.pid
    assert_equal APP.pid, WINDOW.pid
  end

end


class TestElementAttributeWritable < TestElements

  def test_raises_error_for_non_existant_attributes
    assert_raises AX::Element::LookupFailure do
      APP.attribute_writable?(:fake_attribute)
    end
  end

  def test_true_for_writable_attributes
    assert WINDOW.attribute_writable? :position
  end

  def test_false_for_non_writable_attributes
    refute APP.attribute_writable? :title
  end

end


class TestElementSetAttribute < TestElements

  def test_raises_error_if_attribute_is_not_writable
    assert_raises AX::Element::AttributeReadOnly do
      APP.set_attribute :title, 'pantaloons'
    end
  end

  def test_passes_values_down_to_core_correctly
    [25, 75, 50].each do |value|
      slider.set_attribute(:value, value)
      assert_equal value, value_for(slider).to_i
    end
  end

end


# @todo implement missing test cases
class TestElementParamAttributes < TestElements

  def test_empty_for_dock
    assert_empty AX::DOCK.param_attributes
  end

  # def test_not_empty_for_something
  # end
  # def test_contains_proper_info
  # end
  # @todo some other tests copied from testing #attributes

end


# @todo I'll get to this when I need to get to parameterized attributes
class TestElementGetParamAttribute < TestElements

#   def test_returns_nil_for_non_existent_attributes
#   end
#   def test_fetches_attribute
#   end

end


class TestElementActions < TestElements

  def test_empty_an_app
    assert_empty APP.actions
  end

  def test_not_empty_for_dock_item
    refute_empty WINDOW.actions
  end

  def test_contains_proper_info
    assert_includes WINDOW.actions, KAXRaiseAction
  end

end


class TestElementPerformAction < TestElements

  def test_raise_error_for_non_existant_action
    assert_raises AX::Element::LookupFailure do
      APP.perform_action(:fake_action)
    end
  end

  def test_returns_boolean
    [:increment, :decrement].each do |action|
      assert_equal true, slider.perform_action(action)
    end
  end

  # this is meant to test the cache hit case
  def test_only_performs_action_if_object_has_the_action
    no_button.perform_action(:press) # make sure :press is cached
    assert_raises AX::Element::LookupFailure do
      WINDOW.perform_action(:press)
    end
  end

  def test_actually_performs_action
    before = value_for(slider)
    slider.perform_action(:increment)
    after = value_for(slider)
    assert after > before
    slider.perform_action(:decrement)
    assert_equal before, value_for(slider)
  end

end


class TestElementSearch < TestElements

  def test_plural_calls_find_all
    assert_instance_of Array, slider.search(:value_indicators)
  end

  def test_singular_calls_find
    assert_kind_of AX::Element, APP.search(:window)
  end

  def test_works_with_no_filters
    assert_equal WINDOW, APP.search(:window)
  end

  def test_forwards_all_filters
    assert_equal WINDOW, APP.search(:window, title:'AXElementsTester')
    assert_equal nil, slider.search(:value_indicator, help:'Cookie')
  end

end


class TestElementMethodMissing < TestElements

  def test_gets_attribute_if_attribute_found
    assert_equal 'AXElementsTester', APP.title
  end

  def test_does_search_if_not_attribute_but_has_children
    indicator = slider.value_indicator
    assert_instance_of AX::ValueIndicator, indicator
  end

  def test_calls_super_if_not_attribute_and_no_children
    assert_raises NoMethodError do no_button.list end
  end

end


class TestElementOnNotification < TestElements

  def teardown
    class << AX
      alias_method :register_for_notif, :old_register_for_notif
    end
  end

  def test_forwards_info_properly
    class << AX
      alias_method :old_register_for_notif, :register_for_notif
      def register_for_notif ref, notif, &block
        CFGetTypeID(ref) == AXUIElementGetTypeID() && notif == KAXWindowCreatedNotification
      end
    end
    assert APP.on_notification(:window_created)
  end

  def test_does_no_translation_for_custom_notifications
    class << AX
      alias_method :old_register_for_notif, :register_for_notif
      def register_for_notif ref, notif, &block
        notif == 'Cheezburger'
      end
    end
    assert APP.on_notification('Cheezburger')
  end

end


class TestElementInspect < TestElements

  def test_includes_attributes
    output = APP.inspect
    assert_match /@attributes=/, output
    assert_match /Title/, output
  end

  def test_strips_prefixes_and_quotes_from_attributes
    output = APP.inspect
    refute_match /AXTitle/, output
    refute_match /"Title"/, output
  end

end


# @todo Test this once the recursive feature starts working
# class TestElementPrettyPrint < TestElements
#   def test_hash_of_attributes
#     # is a hash
#     # has attributes as the keys
#     # has the correct values
#   end
#   # def test_is_recursive
#   # end
# end


class TestElementRespondTo < TestElements

  def test_true_for_attributes_object_has
    assert APP.respond_to?(:title)
  end

  def test_false_for_attributes_object_does_not_have
    APP.respond_to?(:title_ui_element)
  end

  def test_false_for_search_names
    refute APP.respond_to?(:window)
  end

  def test_still_works_for_regular_methods
    assert AX::DOCK.respond_to?(:attributes)
    refute AX::DOCK.respond_to?(:crazy_thing_that_cant_work)
  end

end


class TestElementToPoint < TestElements

  def test_forwards_to_attribute_method
    obj = WINDOW.dup
    def obj.attribute arg
      arg == :position
    end
    assert obj.to_point
  end

end


class TestElementMethods < TestElements

  def test_includes_objects_attributes
    assert_includes APP.methods, :title
    assert_includes APP.methods, :children
    assert_includes WINDOW.methods, :lol
    assert_includes WINDOW.methods, :nyan
  end

  def test_does_not_break_interface_and_calls_super
    list = APP.methods
    [:send, :freeze, :nil?].each do |name|
      assert_includes list, name
    end
    list = APP.methods(false)
    [:send, :freeze, :nil?].each do |name|
      refute_includes list, name
    end
    list = APP.methods(true, true)
    [:isEqual, :infoForBinding, :valueForKeyPath].each do |name|
      assert_includes list, name
    end
  end

end


class TestElementEquivalence < TestElements

  def app
    AX::Element.new AXUIElementCreateApplication(APP_PID)
  end

  def dock
    AX::Element.new AXUIElementCreateApplication(pid_for 'com.apple.dock')
  end

  def window
    AX.attr_of_element(APP_REF, KAXMainWindowAttribute)
  end

  def list
    dock.attribute(KAXChildrenAttribute).first
  end

  def test_equal_to_self_at_app_level
    assert APP == app
    assert APP.eql? app
    assert APP.equal? app
    refute APP != app
  end

  def test_equal_to_self_for_arbitrary_object
    assert WINDOW == window
    assert WINDOW.eql? window
    assert WINDOW.equal? window
    refute WINDOW != window
  end

  # not equal (inter-app)
  def test_not_equal_between_different_apps
    refute app == dock
    refute app.eql? dock
    refute app.equal? dock
    assert app != dock
  end

  # not equal (intra-app)
  def test_not_equal_inside_app_with_differnt_objects
    refute app == window
    refute app.eql? window
    refute app.equal? window
    assert app != window
  end

end
