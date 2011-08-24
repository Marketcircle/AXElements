# -*- coding: utf-8 -*-

class TestElements < TestAX

  APP    = AX::Element.new REF
  WINDOW = AX::Element.attribute_for REF, KAXMainWindowAttribute

  def window_children
    @@window_children ||= WINDOW.attribute :children
  end

  def no_button
    @@no_button ||= window_children.find do |item|
      item.is_a?(AX::Button) && attribute_for(item.ref, KAXTitleAttribute) == 'No'
    end
  end

  def maybe_button
    @@maybe_button ||= window_children.find do |item|
      item.is_a?(AX::Button) && attribute_for(item.ref, KAXTitleAttribute) == 'Maybe So'
    end
  end

  def slider
    @@slider ||= window_children.find { |item| item.class == AX::Slider }
  end

  def check_box
    @@check_box ||= window_children.find { |item| item.class == AX::CheckBox }
  end

  def static_text
    @@static_text ||= window_children.find { |item| item.class == AX::StaticText }
  end

  def table
    @@table ||= WINDOW.attribute(:children).find do |element|
      element.respond_to?(:identifier) &&
        element.attribute(:identifier) == 'table'
    end.attribute(:children).find do |element|
      element.class == AX::Table
    end
  end

  def value_for element
    AX.attr_of_element(element.ref, KAXValueAttribute)
  end

end


class TestElementLookupFailure < TestElements

  def test_kind_of_argument_error
    assert_kind_of ArgumentError, AX::Element::LookupFailure.new(:blah)
  end

  def test_correct_message
    exception = AX::Element::LookupFailure.new(:test)
    assert_match /was not found/, exception.message
  end

end


class TestElementReadOnlyAttribute < TestElements

  def test_kind_of_method_missing_error
    assert_kind_of NoMethodError, AX::Element::ReadOnlyAttribute.new(:blah)
  end

  def test_correct_message
    exception = AX::Element::ReadOnlyAttribute.new(:test)
    assert_match /read only attribute/, exception.message
  end

end


class TestElementSearchFailure < TestElements

# some interesting scenarios
#  searching a table with a lot of rows
#    in this test, our variable is the number of rows
#  search a tall tree
#    in this test, our variable is how tall the tree is
#  search with no filters
#    this is a simple case that should be thrown in as a
#    control, it will help gauge how much search performance
#    depends on the core implementation of the AX module
#  search with a lot of filters
#    this test will become more important as the filtering
#    logic becomes more complex due to supporting different
#    ideas (e.g. the :title_ui_element hack that exists in v0.4)


  def minimal_exception
    AX::Element::SearchFailure.new(WINDOW, :test, nil)
  end

  def test_correct_message
    pattern = /Could not find `test` as a child of AX::StandardWindow/
    assert_match pattern, minimal_exception.message
  end

  def test_includes_trace
    trace = minimal_exception.message.split('Element Path:').last
    assert_match /AX::StandardWindow "AXElementsTester"/, trace
    assert_match /AX::Application "AXElementsTester" 2 children/, trace
  end

  def test_includes_filters_if_filters_given
    exception = AX::Element::SearchFailure.new(WINDOW, :test, attr: 'value', other: 1)
    assert_match /`test\(attr: "value", other: 1\)`/, exception.message
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


class TestElementAttribute < TestElements

  def test_raises_for_non_existent_attributes
    assert_raises AX::Element::LookupFailure do
      APP.attribute :fakeattribute
    end
  end

  def test_raises_if_cache_hit_but_object_does_not_have_the_attribute
    WINDOW.attribute :nyan? # make sure attr resolves to a constant first
    assert_raises AX::Element::LookupFailure do
      APP.attribute :nyan?
    end
  end

  def bench_string_attribute
    assert_performance_linear do |n|
      n.times { APP.attribute(:title) }
    end
  end

  def bench_boolean_attribute
    assert_performance_linear do |n|
      n.times { WINDOW.attribute(:focused) }
    end
  end

  def bench_children_array
    assert_performance_linear do |n|
      n.times { table.attribute(:columns) }
    end
  end

  def bench_element_attribute
    assert_performance_linear do |n|
      n.times { WINDOW.attribute(:parent) }
    end
  end

  def bench_boxed_attribute
    assert_performance_linear do |n|
      n.times { WINDOW.attribute(:position) }
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


class TestElementAttributeParsesData < TestElements

  def test_does_not_return_raw_values
    assert_kind_of AX::Element, APP.attribute(:menu_bar)
  end

  def test_does_not_return_raw_values_in_array
    assert_kind_of AX::Element, APP.attribute(:children).first
  end

  def test_returns_nil_for_nil_attributes
    assert_nil WINDOW.attribute(:proxy)
  end

  def test_returns_boolean_false_for_false_attributes
    assert_equal false, APP.attribute(:enhanced_user_interface)
  end

  def test_returns_boolean_true_for_true_attributes
    assert_equal true, WINDOW.attribute(:main)
  end

  def test_wraps_axuielementref_objects
    # need intermediate step to make sure AX::MenuBar exists
    ret = APP.attribute(:menu_bar)
    assert_instance_of AX::MenuBar, ret
  end

  def test_returns_array_for_array_attributes
    assert_kind_of Array, APP.attribute(:children)
  end

  def test_returned_arrays_are_not_empty_when_they_should_have_stuff
    refute_empty APP.attribute(:children)
  end

  def test_returned_element_arrays_do_not_have_raw_elements
    assert_kind_of AX::Element, APP.attribute(:children).first
  end

  def test_returns_number_for_number_attribute
    assert_instance_of Fixnum, check_box.attribute(:value)
  end

  def test_returns_array_of_numbers_when_attribute_has_an_array_of_numbers
    # could be a float or a fixnum, be more lenient
    assert_kind_of NSNumber, slider.attribute(:allowed_values).first
  end

  def test_returns_a_cgsize_for_size_attributes
    assert_instance_of CGSize, WINDOW.attribute(:size)
  end

  def test_returns_a_cgpoint_for_point_attributes
    assert_instance_of CGPoint, WINDOW.attribute(:position)
  end

  def test_returns_a_cfrange_for_range_attributes
    assert_instance_of CFRange, static_text.attribute(:visible_character_range)
  end

  def test_returns_a_cgrect_for_rect_attributes
    assert_kind_of CGRect, WINDOW.attribute(:lol)
  end

  def test_works_with_strings
    assert_instance_of String, APP.attribute(:title)
  end

  def test_works_with_urls
    assert_instance_of NSURL, WINDOW.attribute(:url)
  end

end


class TestElementAttributeChoosesCorrectClasseForElements < TestElements

  def scroll_area
    window_children.find { |item| item.class == AX::ScrollArea }
  end

  def test_chooses_role_if_no_subrole
    assert_instance_of AX::Application, WINDOW.attribute(:parent)
  end

  def test_chooses_subrole_if_it_exists
    classes = window_children.map &:class
    assert_includes classes, AX::CloseButton
    assert_includes classes, AX::SearchField
  end

  def test_chooses_role_if_subrole_is_nil
    web_area = scroll_area.attribute(:children).first
    assert_instance_of AX::WebArea, web_area
  end

  # we use dock items here, because this is an easy case of
  # the role class being recursively created when trying to
  # create the subrole class
  def test_creates_role_for_subrole_if_it_does_not_exist_yet
    dock     = AX::Element.new AXUIElementCreateApplication(pid_for 'com.apple.dock')
    list     = dock.attribute(:children).first
    children = list.attribute(:children).map &:class
    assert_includes children, AX::ApplicationDockItem
  end

  # @todo this happens when accessibility is not implemented correctly,
  #       and the problem with fixing it is the performance cost
  def test_chooses_role_if_subrole_is_unknown_type
    skip 'This case is not handled right now'
  end

  # @todo Get another case to test, something not used elsewhere
  def test_creates_inheritance_chain
    WINDOW.attribute :children
    assert_equal AX::Button, AX::CloseButton.superclass
    assert_equal AX::Element, AX::Button.superclass
  end

end


class TestElementDescription < TestElements

  def test_raise_error_if_object_has_no_description
    assert_raises AX::Element::LookupFailure do
      APP.description
    end
  end

  def test_gets_description
    assert_equal 'The cake is a lie!', no_button.description
  end

  def test_responds_to # true when it exist, false otherwise
    skip 'Leaving this as a known bug until it is a real problem'
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
      APP.attribute_writable? :fake_attribute
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
    assert_raises AX::Element::ReadOnlyAttribute do
      APP.set_attribute :title, 'pantaloons'
    end
  end

  def test_passes_values_down_to_core_correctly
    [25, 75, 50].each do |value|
      slider.set_attribute :value, value
      assert_equal value, value_for(slider).to_i
    end
  end

  # important test since it checks if we wrap boxes
  def test_set_window_size
    original_size = WINDOW.attribute :size
    new_size = original_size.dup
    new_size.height /= 2
    WINDOW.set_attribute :size, original_size
    assert_equal original_size, WINDOW.attribute(:size)
  ensure
    WINDOW.set_attribute :size, original_size
  end

end


class TestElementParamAttributes < TestElements

  def test_empty_for_dock
    assert_empty APP.param_attributes
  end

  def test_not_empty_for_search_field
    assert_includes static_text.param_attributes, KAXStringForRangeParameterizedAttribute
    assert_includes static_text.param_attributes, KAXLineForIndexParameterizedAttribute
    assert_includes static_text.param_attributes, KAXBoundsForRangeParameterizedAttribute
  end

end


class TestElementGetParamAttribute < TestElements

  def test_raises_exception_for_non_existent_attribute
    assert_raises AX::Element::LookupFailure do
      static_text.param_attribute :bob_loblaw, nil
    end
  end

  def test_contains_proper_info
    attr = static_text.param_attribute(:string_for_range, CFRange.new(0, 5))
    assert_equal 'AXEle', attr
  end

  def test_get_attributed_string
    attr = static_text.param_attribute(:attributed_string_for_range, CFRange.new(0, 5))
    assert_kind_of NSAttributedString, attr
    assert_equal 'AXEle', attr.string
  end

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
      APP.perform_action :fake_action
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
    before = value_for slider
    slider.perform_action :increment
    after = value_for slider
    assert after > before
    slider.perform_action :decrement
    assert_equal before, value_for(slider)
  end

end


class TestElementSearch < TestElements

  def test_boxes_becomes_find_all_box
    assert_instance_of AX::CheckBox, WINDOW.search(:check_boxes).first
  end

  def test_sliders_becomes_find_all_slider
    assert_equal slider.ref, WINDOW.search(:sliders).first.ref
  end

  def test_value_indicators_becomes_find_all_value_indicator
    assert_instance_of AX::ValueIndicator, slider.search(:value_indicators).first
  end

  def test_window_becomes_find_window
    assert_kind_of AX::Window, APP.search(:window)
  end

  def test_value_indicator_becomes_find_value_indicator
    assert_instance_of AX::ValueIndicator, slider.search(:value_indicator)
  end

  def test_works_with_no_filters
    assert_equal WINDOW, APP.search(:window)
  end

  def test_forwards_all_filters
    assert_equal WINDOW, APP.search(:window, title: 'AXElementsTester')
    assert_equal nil, slider.search(:value_indicator, help: 'Cookie')
  end

end


class TestElementMethodMissing < TestElements

  def test_gets_attribute_if_attribute_found
    assert_equal 'AXElementsTester', APP.title
  end

  def test_gets_param_attribute_if_param_attribute_found_and_not_attribute
    assert_equal 'AXEle', static_text.string_for_range(CFRange.new 0, 5)
  end

  def test_does_search_if_not_attribute_and_not_param_attribute_but_has_children
    indicator = slider.value_indicator
    assert_instance_of AX::ValueIndicator, indicator
  end

  def test_raises_if_search_returns_blank
    assert_raises AX::Element::SearchFailure do
      APP.element_that_does_not_exist
    end
  end

  def test_calls_super_if_not_attribute_and_no_children
    assert_raises NoMethodError do no_button.list end
  end

  def test_processes_attribute_return_values
    assert_instance_of AX::StandardWindow, no_button.parent
    assert_instance_of CGPoint, no_button.position
  end

  def bench_attribute_string
    assert_performance_linear do |n|
      n.times { WINDOW.attribute(:title) }
    end
  end

  def bench_attribute_boolean
    assert_performance_linear do |n|
      n.times { WINDOW.focused? }
    end
  end

  def bench_attribute_child_array
    assert_performance_linear do |n|
      n.times { table.columns }
    end
  end

  def bench_attribute_boxed
    assert_performance_linear do |n|
      n.times { WINDOW.position }
    end
  end

  def bench_attribute_element
    assert_performance_linear do |n|
      n.times { WINDOW.parent }
    end
  end

end


class TestElementOnNotification < TestElements

  def test_does_no_translation_for_custom_notifications
    class << AX; alias_method :old_register_for_notif, :register_for_notif; end
    def AX.register_for_notif ref, notif, &block
      notif == 'Cheezburger'
    end
    assert APP.on_notification('Cheezburger')
  ensure
    class << AX; alias_method :register_for_notif, :old_register_for_notif; end
  end

  def radio_group
    @@radio_group ||= window_children.find do |item|
      item.class == AX::RadioGroup
    end
  end

  def radio_gaga
    @@gaga ||= radio_group.attribute(:children).find do |item|
      item.attribute(:title) == 'Gaga'
    end
  end

  # this test is weird, sometimes the radio group sends the notification
  # first and other times the button sends it, but for the sake of the
  # test we only care that one of them sent the notif
  def test_yielded_proper_objects
    element = notification = nil
    radio_gaga.on_notification :value_changed do |el,notif|
      element, notification = el, notif
    end

    action_for radio_gaga.ref, KAXPressAction

    assert AX.wait_for_notif 1.0
    assert_kind_of NSString, notification
    assert_kind_of AX::Element, element
  end

end


class TestElementSizeOf < TestElements

  def test_raises_for_bad
    assert_raises AX::Element::LookupFailure do
      APP.size_of :roflcopter
    end
  end

  def test_returns_number
    assert_equal 2, APP.size_of(:children)
  end

end


class TestElementInspect < TestElements

  def app
    @@app ||= APP.inspect
  end

  def window
    @@window ||= WINDOW.inspect
  end

  def text
    @@text ||= static_text.inspect
  end

  def button
    @@button ||= no_button.inspect
  end

  def slidr
    @@slidr ||= slider.inspect
  end

  def test_inspect_includes_header_and_tail
    assert_match /^\#<AX::Element/, app
    assert_match />$/,              app
  end

  def test_inspect_includes_position_if_possible
    position_regexp = /\(\d+\.\d+, \d+\.\d+\)/
    assert_match position_regexp, window
    refute_match position_regexp, app
  end

  def test_inspect_includes_children_if_possible
    child_regexp = /\d+ child/
    assert_match child_regexp, app
    refute_match child_regexp, text
  end

  def test_inspect_includes_enabled_if_possible
    enabled_regexp = /enabled\[.\]/
    assert_match enabled_regexp, button
    refute_match enabled_regexp, app
  end

  def test_inspect_includes_focused_if_possible
    focused_regexp = /focused\[.\]/
    assert_match focused_regexp, slider.inspect
    refute_match focused_regexp, app
  end

  def test_inspect_always_has_identifier
    title_regexp = /"AXElementsTester"/
    assert_match title_regexp, app
    assert_match title_regexp, window
    assert_match title_regexp, text

    assert_match /"No"/, button
    assert_match /value=50/, slidr
  end

end


class TestElementRespondTo < TestElements

  def test_true_for_attributes_object_has
    assert_respond_to APP, :title
  end

  def test_false_for_attributes_object_does_not_have
    refute_respond_to APP, :title_ui_element
  end

  def test_true_for_parameterized_attributes
    assert_respond_to static_text, :string_for_range
  end

  def test_false_for_search_names
    refute_respond_to APP, :window
  end

  def test_still_works_for_regular_methods
    assert_respond_to APP, :attributes
    refute_respond_to APP, :crazy_thing_that_cant_work
  end

end


class TestElementToPoint < TestElements

  def test_makes_point_in_center_of_element
    obj = WINDOW.dup
    def obj.attribute arg
      arg == :position ? CGPointMake(400, 350) : CGSizeMake(200, 500)
    end
    assert_equal CGPointMake(500, 600), obj.to_point
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
    AX::Element.new AXUIElementCreateApplication(PID)
  end

  def dock
    AX::Element.new AXUIElementCreateApplication(pid_for 'com.apple.dock')
  end

  def window
    AX::Element.new AX.attr_of_element(REF, KAXMainWindowAttribute)
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


class TestStripPrefix < MiniTest::Unit::TestCase

  def prefix_test before, after
    assert_equal after, AX::Element.strip_prefix(before)
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
