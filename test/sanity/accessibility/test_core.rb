# -*- coding: utf-8 -*-

require 'test/helper'
require 'accessibility/core'


class TestAccessibilityCore < MiniTest::Unit::TestCase

  def window
    @@window ||= REF.attribute(KAXMainWindowAttribute)
  end

  def child name
    window.children.find { |item|
      (block_given? ? yield(item) : true) if item.role == name
    }
  end

  def slider;      @@slider      ||= child KAXSliderRole;      end
  def check_box;   @@check_box   ||= child KAXCheckBoxRole;    end
  def pop_up;      @@pop_up      ||= child KAXPopUpButtonRole; end
  def search_box;  @@search_box  ||= child KAXTextFieldRole;   end
  def static_text; @@static_text ||= child(KAXStaticTextRole) { |x| x.value.match /My Little Pony/           } end
  def yes_button;  @@yes_button  ||= child(KAXButtonRole)     { |x| x.attribute(KAXTitleAttribute) == 'Yes'  } end
  def bye_button;  @@bye_button  ||= child(KAXButtonRole)     { |x| x.attribute(KAXTitleAttribute) == 'Bye!' } end
  def no_button;   @@no_button   ||= child(KAXButtonRole)     { |x| x.attribute(KAXTitleAttribute) == 'No'   } end
  def web_area;    @@web_area    ||= child("AXScrollArea")    { |x| x.attribute("AXDescription"  ) == 'Test Web Area' }.children.first end
  def text_area;   @@text_area   ||= child("AXScrollArea")    { |x| x.attributes.include?("AXIdentifier") && x.attribute("AXIdentifier") == 'Text Area' }.children.first end

  def invalid_ref
    bye_button # guarantee that it is cached
    @@dead ||= no_button.perform KAXPressAction
    bye_button
  end

  def app
    @@app ||= Regexp.new(Regexp.escape(REF.inspect))
  end

  def assert_error args, should_raise: klass, with_fragments: msgs
    e = assert_raises(klass) { (@derp || REF).handle_error *args }
    assert_match /test_core.rb:41/, e.backtrace.first unless RUNNING_COMPILED
    msgs.each { |msg| assert_match msg, e.message }
  end



  ##
  # AFAICT every accessibility object **MUST** have attributes, so
  # there are no tests to check what happens when they do not exist;
  # though I am quite sure that AXElements will raise an exception.

  def test_attributes
    attrs = REF.attributes
    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute
  end

  def test_attributes_is_empty_for_dead_elements
    assert_empty invalid_ref.attributes
  end

  def test_attribute
    assert_equal 'AXElementsTester',  window.attribute(KAXTitleAttribute  )
    assert_equal false,               window.attribute(KAXFocusedAttribute)
    assert_equal CGSizeMake(555,483), window.attribute(KAXSizeAttribute   )
    assert_equal REF,                 window.attribute(KAXParentAttribute )
    assert_equal 10..19,              window.attribute("AXPie"            )
  end

  def test_attribute_when_no_value
    assert_nil window.attribute(KAXGrowAreaAttribute)
  end

  def test_attribute_when_dead
    assert_nil   invalid_ref.attribute(KAXRoleAttribute)
    assert_empty invalid_ref.attribute(KAXChildrenAttribute)
  end

  def test_attribute_when_not_supported_attribute
    assert_nil REF.attribute('MADEUPATTRIBUTE')
  end

  def test_role
    assert_equal KAXApplicationRole, REF.role
  end

  def test_subrole
    assert_equal KAXStandardWindowSubrole, window.subrole
    assert_nil   web_area.subrole
  end

  def test_children
    assert_equal    REF.attribute(KAXChildrenAttribute), REF.children
    assert_equal slider.attribute(KAXChildrenAttribute), slider.children
  end

  def test_value
    assert_equal check_box.attribute(KAXValueAttribute), check_box.value
    assert_equal    slider.attribute(KAXValueAttribute), slider.value
  end

  def test_size_of
    assert_equal REF.children.size, REF.size_of(KAXChildrenAttribute)
    assert_equal 0,                 pop_up.size_of(KAXChildrenAttribute)
  end

  def test_size_of_0_for_dead_element
    assert_equal 0, invalid_ref.size_of(KAXChildrenAttribute)
  end

  def test_writable
    refute REF.writable?    KAXTitleAttribute
    assert window.writable? KAXMainAttribute
  end

  def test_writable_false_for_dead_cases
    refute invalid_ref.writable? KAXRoleAttribute
  end

  def test_writable_false_for_bad_attributes
    refute REF.writable? 'FAKE'
  end

  def test_set_number
    [25, 75, 50].each do |number|
      assert_equal number, slider.set(KAXValueAttribute, number)
      assert_equal number, slider.value
    end
  end

  def test_set_string
    [Time.now.to_s, ''].each do |string|
      assert_equal string, search_box.set(KAXValueAttribute, string)
      assert_equal string, search_box.value
    end
  end

  def test_set_wrapped
    text_area.set KAXValueAttribute, 'hey-o'

    text_area.set KAXSelectedTextRangeAttribute, 0..3
    assert_equal 0..3, text_area.attribute(KAXSelectedTextRangeAttribute)

    text_area.set KAXSelectedTextRangeAttribute, 1...4
    assert_equal 1..3, text_area.attribute(KAXSelectedTextRangeAttribute)
  ensure
    text_area.set KAXValueAttribute, ''
  end

  def test_set_attr_handles_errors
    assert_raises(ArgumentError) { REF.set 'FAKE', true }
  end

  def test_parameterized_attributes
    assert_empty REF.parameterized_attributes

    attrs = static_text.parameterized_attributes
    assert_includes attrs, KAXStringForRangeParameterizedAttribute
    assert_includes attrs, KAXLineForIndexParameterizedAttribute
    assert_includes attrs, KAXBoundsForRangeParameterizedAttribute
  end

  def test_parameterized_attributes_empty_for_dead_elements
    assert_empty invalid_ref.parameterized_attributes
  end

  def test_parameterized_attribute
    expected = 'My Li'

    attr = static_text.parameterized_attribute(KAXStringForRangeParameterizedAttribute, 0..4)
    assert_equal expected, attr

    attr = static_text.parameterized_attribute(KAXAttributedStringForRangeParameterizedAttribute, 0..4)
    assert_equal expected, attr.string
  end

  def test_parameterized_attribute_handles_dead_elements_and_no_value
    assert_nil invalid_ref.parameterized_attribute(KAXStringForRangeParameterizedAttribute, 0..0)

    # Should add a test case to test the no value case, but it will have
    # to be fabricated in the test app.
  end

  def test_parameterized_attribute_handles_errors
    assert_raises(ArgumentError) {
      REF.parameterized_attribute(KAXStringForRangeParameterizedAttribute, 0..1)
    }
  end

  def test_action_names
    assert_empty                   REF.actions
    assert_equal [KAXPressAction], yes_button.actions
  end

  def test_perform_action
    2.times do # twice so it should be back where it started
      val = check_box.value
      check_box.perform KAXPressAction
      refute_equal val, check_box.value
    end

    val  = slider.value
    slider.perform KAXIncrementAction
    assert slider.value > val

    val  = slider.value
    slider.perform KAXDecrementAction
    assert slider.value < val
  end

  def test_action_handles_errors
    assert_raises(ArgumentError) { REF.perform nil }
  end

  ##
  # The keyboard simulation stuff is a bit weird...

  def test_post
    events = [[0x56,true], [0x56,false], [0x54,true], [0x54,false]]
    string = '42'

    search_box.set KAXFocusedAttribute, true
    REF.post events

    assert_equal string, search_box.value

  ensure # reset for next test
    search_box.set KAXValueAttribute, ''
  end

  ##
  # Kind of a bad test right now because the method itself
  # lacks certain functionality that needs to be added...

  def test_element_at
    point   = no_button.attribute(KAXPositionAttribute)

    element = REF.element_at point
    assert_equal no_button, element, "#{no_button.inspect} and #{element.inspect}"

    element = REF.system_wide.element_at point
    assert_equal no_button, element, "#{no_button.inspect} and #{element.inspect}"

    assert_respond_to element, :role
  end

  # def test_element_at_returns_nil_on_empty_space
  #   skip 'How do I guarantee an empty space on screen?'
  #   # btw, [0,0] returns something
  # end

  def test_application_for
    # @note Should call CFEqual() under the hood, which is what we want
    assert_equal REF, REF.application_for(PID)
  end

  def test_application_for_raises_for_bad_pid
    assert_raises(ArgumentError) { REF.application_for 0 }
  end

  def test_observer
    assert_equal AXObserverGetTypeID(), CFGetTypeID(REF.observer { })
  end

  def test_observer_handles_errors
    assert_raises(ArgumentError) { REF.observer }
  end

  def test_run_loop_source_for
    obsrvr = REF.observer { |_,_,_| }
    assert_equal CFRunLoopSourceGetTypeID(), CFGetTypeID(REF.run_loop_source_for(obsrvr))
  end

  # # more than meets the eye
  def test_notification_registration_and_unregistration
    obsrvr = REF.observer { |_,_,_| }
    assert   REF.register(obsrvr, KAXWindowCreatedNotification)
    assert REF.unregister(obsrvr, KAXWindowCreatedNotification)
  end

  # integration-y
  def test_notification_registers_everything_correctly
    obsrvr = REF.observer do |observer, element, notif|
      @notif_triple = [observer, element, notif]
    end
    REF.register observer, 'Cheezburger'
    source = REF.run_loop_source_for observer
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)

    yes_button.perform KAXPressAction
    yes_button.spin_run_loop

    assert_equal [obsrvr, yes_button, 'Cheezburger'], @notif_triple

  ensure
    return unless source
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
  end

  def test_register_handles_errors
    assert_raises(ArgumentError) {
      REF.register(nil, KAXWindowCreatedNotification)
    }
    assert_raises(ArgumentError) {
      obsrvr = REF.observer { |_,_,_| }
      REF.register(obsrvr, nil)
    }
  end

  def test_unregister_handles_errors
    assert_raises(ArgumentError) {
      REF.unregister(nil, KAXWindowCreatedNotification)
    }
    assert_raises(ArgumentError) {
      obsrvr = REF.observer { |_,_,_| }
      REF.unregister(obsrvr, nil)
    }
  end

  def test_enabled?
    assert REF.enabled?
    # @todo I guess that's good enough?
  end

  def test_pid
    assert_equal PID, REF.pid
    assert_equal PID, window.pid
  end

  def test_pid_is_zero_for_system_wide
    assert_equal 0, REF.system_wide.pid
  end

  def test_system_wide
    assert_equal AXUIElementCreateSystemWide(), REF.system_wide
  end

  def test_application
    assert_equal REF, REF.application
    assert_equal REF, window.application
  end

  def test_set_timeout_for
    assert_equal 10, REF.set_timeout_to(10)
    assert_equal 0,  REF.set_timeout_to(0)
  end

  def test_handle_error_failsafe
       assert_error [99],
      should_raise: RuntimeError,
    with_fragments: [/never reach this line/, /99/]
  end

  def test_handle_failure
       assert_error [KAXErrorFailure],
      should_raise: RuntimeError,
    with_fragments: [/system failure/, app]
  end

  def test_handle_illegal_argument
       assert_error [KAXErrorIllegalArgument],
      should_raise: ArgumentError,
    with_fragments: [/is not an AXUIElementRef/, app]

       assert_error [KAXErrorIllegalArgument, :cake],
      should_raise: ArgumentError,
    with_fragments: [/is not a legal argument/, /the element/, app, /cake/]

       assert_error [KAXErrorIllegalArgument, 'cake', 'chocolate'],
      should_raise: ArgumentError,
    with_fragments: [/can't get\/set "cake" with\/to "chocolate"/, app]

    p = CGPointMake(1,3)
    assert_error [KAXErrorIllegalArgument, p, nil, nil],
      should_raise: ArgumentError,
    with_fragments: [/The point #{p.inspect}/, app]

       assert_error [KAXErrorIllegalArgument, 'cheezburger', 'cake', nil, nil],
      should_raise: ArgumentError,
    with_fragments: [/the observer "cake"/,app,/the notification "cheezburger"/]
  end

  def test_handle_invalid_element
       assert_error [KAXErrorInvalidUIElement],
      should_raise: ArgumentError,
    with_fragments: [/no longer a valid reference/, app]
  end

  def test_handle_invalid_observer
       assert_error [KAXErrorInvalidUIElementObserver, :pie, :cake],
      should_raise: ArgumentError,
    with_fragments: [/no longer a valid observer/, /or was never valid/, app, /cake/]
  end

  def test_handle_cannot_complete
       assert_error [KAXErrorCannotComplete],
      should_raise: RuntimeError,
    with_fragments: [/An unspecified error/, app, /:\(/]

    @derp = REF.application_for pid_for 'com.apple.finder'
    def @derp.pid; false end
       assert_error [KAXErrorCannotComplete],
      should_raise: RuntimeError,
    with_fragments: [/Application for pid/, /Maybe it crashed\?/]
  end

  def test_attr_unsupported
       assert_error [KAXErrorAttributeUnsupported, :cake],
      should_raise: ArgumentError,
    with_fragments: [/does not have/, /:cake attribute/, app]
  end

  def test_action_unsupported
       assert_error [KAXErrorActionUnsupported, :pie],
      should_raise: ArgumentError,
    with_fragments: [/does not have/, /:pie action/, app]
  end

  def test_notif_unsupported
       assert_error [KAXErrorNotificationUnsupported, :cheese],
      should_raise: ArgumentError,
    with_fragments: [/does not support/, /:cheese notification/, app]
  end

  def test_not_implemented
       assert_error [KAXErrorNotImplemented],
      should_raise: NotImplementedError,
    with_fragments: [/does not work with AXAPI/, app]
  end

  def test_notif_registered
       assert_error [KAXErrorNotificationAlreadyRegistered, :lamp],
      should_raise: ArgumentError,
    with_fragments: [/already registered/, /:lamp/, app]
  end

  def test_notif_not_registered
       assert_error [KAXErrorNotificationNotRegistered, :peas],
      should_raise: RuntimeError,
    with_fragments: [/not registered/, /:peas/, app]
  end

  def test_api_disabled
       assert_error [KAXErrorAPIDisabled],
      should_raise: RuntimeError,
    with_fragments: [/AXAPI has been disabled/]
  end

  def test_param_attr_unsupported
       assert_error [KAXErrorParameterizedAttributeUnsupported, :oscar],
      should_raise: ArgumentError,
    with_fragments: [/does not have/, /:oscar parameterized attribute/, app]
  end

  def test_not_enough_precision
       assert_error [KAXErrorNotEnoughPrecision],
      should_raise: RuntimeError,
    with_fragments: [/not enough precision/, '¯\(°_o)/¯']
  end

end


class TestToAXToRubyHooks < MiniTest::Unit::TestCase

  def test_to_ax
    # point_makes_a_value
    value = CGPointZero.to_ax
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(value, 1, ptr)
    assert_equal CGPointZero, ptr.value

    # size_makes_a_value
    value = CGSizeZero.to_ax
    ptr   = Pointer.new CGSize.type
    AXValueGetValue(value, 2, ptr)
    assert_equal CGSizeZero, ptr.value

    # rect_makes_a_value
    value = CGRectZero.to_ax
    ptr   = Pointer.new CGRect.type
    AXValueGetValue(value, 3, ptr)
    assert_equal CGRectZero, ptr.value

    # range_makes_a_value
    range = CFRange.new(5, 4)
    value = range.to_ax
    ptr   = Pointer.new CFRange.type
    AXValueGetValue(value, 4, ptr)
    assert_equal range, ptr.value
  end

  def test_to_axvalue_raises_for_unsupported_boxes
    assert_raises(NotImplementedError) { NSEdgeInsets.new.to_ax }
  end

  def test_to_ax_for_ranges
    assert_equal CFRangeMake(1,10).to_ax, (1..10  ).to_ax
    assert_equal CFRangeMake(1, 9).to_ax, (1...10 ).to_ax
    assert_equal CFRangeMake(0, 3).to_ax, (0..2   ).to_ax
  end

  def test_to_axvalue_for_ranges_raises_for_bad_ranges
    assert_raises(ArgumentError) { (1..-10).to_ax  }
    assert_raises(ArgumentError) { (-5...10).to_ax }
  end

  def test_to_ax_on_other_objects
    obj = Object.new
    assert_equal obj.self, obj.to_ax
  end


  def test_to_ruby
    assert_equal CGPointZero,       CGPointZero      .to_ax.to_ruby
    assert_equal CGSizeMake(10,10), CGSizeMake(10,10).to_ax.to_ruby
    assert_equal Range.new(1,10),   CFRange.new(1,10).to_ax.to_ruby
  end

  def test_to_ruby_on_non_boxes
    obj = Object.new
    assert_equal obj.self, obj.to_ruby
  end

end


class TestMiscCoreExtensions < MiniTest::Unit::TestCase

  def test_to_point
    p = CGPointMake(2,3)
    assert_equal p, p.to_point

    p = CGPointMake(1,3)
    assert_equal p, p.to_a.to_point
  end

  def test_to_size
    s = CGSizeMake(2,4)
    assert_equal s, s.to_a.to_size
  end

  def test_to_rect
    r = CGRectMake(6,7,8,9)
    assert_equal r, r.to_a.map(&:to_a).flatten.to_rect
  end

end
