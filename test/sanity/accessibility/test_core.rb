# -*- coding: utf-8 -*-

require 'test/helper'
require 'accessibility/core'


class TestAccessibilityCore < MiniTest::Unit::TestCase
  include Accessibility::Core

  def window
    @@window ||= (@ref = REF; attribute(KAXMainWindowAttribute))
  end

  def child name
    @ref = window
    children.find { |item|
      @ref = item
      (block_given? ? yield : true) if role == name
    }
  end

  def slider;      @@slider      ||= child KAXSliderRole;      end
  def check_box;   @@check_box   ||= child KAXCheckBoxRole;    end
  def pop_up;      @@pop_up      ||= child KAXPopUpButtonRole; end
  def search_box;  @@search_box  ||= child KAXTextFieldRole;   end
  def static_text; @@static_text ||= child(KAXStaticTextRole) { value.match /My Little Pony/           } end
  def yes_button;  @@yes_button  ||= child(KAXButtonRole)     { attribute(KAXTitleAttribute) == 'Yes'  } end
  def bye_button;  @@bye_button  ||= child(KAXButtonRole)     { attribute(KAXTitleAttribute) == 'Bye!' } end
  def no_button;   @@no_button   ||= child(KAXButtonRole)     { attribute(KAXTitleAttribute) == 'No'   } end
  def web_area
    @@web_area ||= (
      child("AXScrollArea") { attribute("AXDescription") == 'Test Web Area' }
      children.first
    )
  end
  def text_area
    @@text_area ||= (child("AXScrollArea") {
        attributes.include?(KAXIdentifierAttribute) &&
        attribute(KAXIdentifierAttribute) == 'Text Area'
      }
      children.first)
  end

  def set_invalid_ref
    bye_button # guarantee that it is cached
    @@dead ||= (@ref = no_button; perform KAXPressAction)
    @ref     = bye_button
  end

  def app
    @@app ||= Regexp.new(Regexp.escape(REF.inspect))
  end

  def assert_error args, should_raise: klass, with_fragments: msgs
    @ref = REF
    e = assert_raises(klass) { handle_error *args }
    assert_match /test_core.rb:56/, e.backtrace.first unless RUNNING_COMPILED
    msgs.each { |msg| assert_match msg, e.message }
  end



  ##
  # AFAICT every accessibility object **MUST** have attributes, so
  # there are no tests to check what happens when they do not exist;
  # though I am quite sure that AXElements will raise an exception.

  def test_attributes
    @ref = REF
    attrs = attributes

    refute_empty attrs
    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute
  end

  def test_attributes_is_empty_for_dead_elements
    set_invalid_ref
    assert_empty attributes
  end

  def test_attrs_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { attributes }
  end

  def test_attribute
    @ref = window
    assert_equal 'AXElementsTester',  attribute(KAXTitleAttribute  )
    assert_equal false,               attribute(KAXFocusedAttribute)
    assert_equal CGSizeMake(555,483), attribute(KAXSizeAttribute   )
    assert_equal REF,                 attribute(KAXParentAttribute )
    assert_equal 10..19,              attribute("AXPie"            )
  end

  def test_attribute_is_nil_when_no_value_or_dead
    @ref = window
    assert_nil attribute(KAXGrowAreaAttribute)
    set_invalid_ref
    assert_nil attribute(KAXRoleAttribute)
  end

  def test_attribute_handles_errors
    @ref = REF
    assert_raises(ArgumentError) { attribute 'MADEUPATTRIBUTE' }
  end

  def test_role
    @ref = REF
    assert_equal KAXApplicationRole, role
  end

  def test_subrole
    @ref = window
    assert_equal KAXStandardWindowSubrole, subrole
    @ref = web_area
    assert_nil   subrole
  end

  def test_children
    @ref = REF
    assert_equal attribute(KAXChildrenAttribute), children
    @ref = slider
    assert_equal attribute(KAXChildrenAttribute), children
  end

  def test_value
    @ref = check_box
    assert_equal attribute(KAXValueAttribute), value
    @ref = slider
    assert_equal attribute(KAXValueAttribute), value
  end

  def test_size_of
    @ref = REF
    assert_equal children.size, size_of(KAXChildrenAttribute)
    @ref = pop_up
    assert_equal 0,             size_of(KAXChildrenAttribute)
  end

  def test_size_of_0_for_dead_element
    set_invalid_ref
    assert_equal 0, size_of(KAXChildrenAttribute)
  end

  def test_size_of_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { size_of 'pie' }
  end

  def test_writable
    @ref = REF
    refute writable? KAXTitleAttribute
    @ref = window
    assert writable? KAXMainAttribute
  end

  def test_writable_false_for_dead_cases
    set_invalid_ref
    refute writable? KAXRoleAttribute
  end

  def test_writable_handles_errors
    @ref = REF
    assert_raises(ArgumentError) { writable? 'FAKE' }
  end

  def test_set_number
    @ref = slider
    [25, 75, 50].each do |number|
      assert_equal number, set(KAXValueAttribute, number)
      assert_equal number, value
    end
  end

  def test_set_string
    @ref = search_box
    [Time.now.to_s, ''].each do |string|
      assert_equal string, set(KAXValueAttribute, string)
      assert_equal string, value
    end
  end

  def test_set_wrapped
    @ref = text_area
    set KAXValueAttribute, 'hey-o'

    set KAXSelectedTextRangeAttribute, 0..3
    assert_equal 0..3, attribute(KAXSelectedTextRangeAttribute)

    set KAXSelectedTextRangeAttribute, 1...4
    assert_equal 1..3, attribute(KAXSelectedTextRangeAttribute)
  ensure
    set KAXValueAttribute, ''
  end

  def test_set_attr_handles_errors
    @ref = REF
    assert_raises(ArgumentError) { set 'FAKE', true }
  end

  def test_parameterized_attributes
    @ref = REF
    assert_empty parameterized_attributes

    @ref  = static_text
    attrs = parameterized_attributes
    assert_includes attrs, KAXStringForRangeParameterizedAttribute
    assert_includes attrs, KAXLineForIndexParameterizedAttribute
    assert_includes attrs, KAXBoundsForRangeParameterizedAttribute
  end

  def test_parameterized_attributes_empty_for_dead_elements
    set_invalid_ref
    assert_empty parameterized_attributes
  end

  def test_parameterized_attributes_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { parameterized_attributes }
  end

  def test_attribute_for_parameter
    @ref     = static_text
    expected = 'My Li'

    attr = attribute KAXStringForRangeParameterizedAttribute, for_parameter: 0..4
    assert_equal expected, attr
    attr = attribute KAXAttributedStringForRangeParameterizedAttribute, for_parameter: 0..4
    assert_equal expected, attr.string
  end

  def test_attribute_for_parameter_handles_dead_elements_and_no_value
    set_invalid_ref
    assert_nil attribute(KAXStringForRangeParameterizedAttribute, for_parameter: 0..0)

    # Should add a test case to test the no value case, but it will have
    # to be fabricated in the test app.
  end

  def test_attribute_for_parameter_handles_errors
    @ref = REF
    assert_raises(ArgumentError) {
      attribute(KAXStringForRangeParameterizedAttribute, for_parameter: 0..1)
    }
  end

  def test_action_names
    @ref = REF
    assert_empty                                           actions
    @ref = yes_button
    assert_equal [KAXPressAction],                         actions
    @ref = slider
    assert_equal [KAXIncrementAction, KAXDecrementAction], actions
  end

  def test_actions_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { actions }
  end

  def test_perform_action
    @ref = check_box
    2.times do # twice so it should be back where it started
      val = value
      perform KAXPressAction
      refute_equal val, value
    end

    @ref = slider
    val  = value
    perform KAXIncrementAction
    assert value > val

    val  = value
    perform KAXDecrementAction
    assert value < val
  end

  def test_action_handles_errors
    @ref = REF
    assert_raises(ArgumentError) { perform nil }
    @ref = nil
    assert_raises(ArgumentError) { perform KAXPressAction }
  end

  ##
  # The keyboard simulation stuff is a bit weird...

  def test_post_events_to
    events = [[0x56,true], [0x56,false], [0x54,true], [0x54,false]]
    string = '42'

    @ref = search_box
    set KAXFocusedAttribute, true
    @ref = REF
    post events

    @ref = search_box
    assert_equal string, value

  ensure # reset for next test
    set KAXValueAttribute, ''
  end

  def test_post_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { post [[56,true],[56,false]] }
  end

  ##
  # Kind of a bad test right now because the method itself
  # lacks certain functionality that needs to be added...

  def test_element_at
    @ref    = no_button
    point   = attribute(KAXPositionAttribute)

    @ref    = REF
    element = element_at point
    assert_equal no_button, element, "#{no_button.inspect} and #{element.inspect}"

    @ref    = system_wide
    element = element_at point
    assert_equal no_button, element, "#{no_button.inspect} and #{element.inspect}"
  end

  def test_element_at_returns_nil_on_empty_space
    skip 'How do I guarantee an empty space on screen?'
    # btw, [0,0] returns something
  end

  def test_element_at_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { element_at [1,1] }
  end

  def test_application_for
    # @note Should call CFEqual() under the hood, which is what we want
    assert_equal REF, application_for(PID)
  end

  def test_application_for_raises_for_bad_pid
    assert_raises(ArgumentError) { application_for 0 }
  end

  def test_observer
    @ref = REF
    assert_equal AXObserverGetTypeID(), CFGetTypeID(observer { })
  end

  def test_observer_handles_errors
    @ref = REF
    assert_raises(ArgumentError) { observer }
  end

  def test_run_loop_source_for
    @ref = REF
    obsrvr = observer { |_,_,_| }
    assert_equal CFRunLoopSourceGetTypeID(), CFGetTypeID(run_loop_source_for(obsrvr))
  end

  # more than meets the eye
  def test_notification_registration_and_unregistration
    @ref = REF
    obsrvr = observer { |_,_,_| }
    assert   register(obsrvr,     to_receive: KAXWindowCreatedNotification)
    assert unregister(obsrvr, from_receiving: KAXWindowCreatedNotification)
  end

  # integration-y
  def test_notification_registers_everything_correctly
    @ref = REF

    obsrvr = observer do |observer, element, notif|
      @notif_triple = [observer, element, notif]
    end
    register observer, to_receive: 'Cheezburger'
    source = run_loop_source_for observer
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)

    @ref = yes_button
    perform KAXPressAction
    spin_run_loop

    assert_equal [obsrvr, yes_button, 'Cheezburger'], @notif_triple

  ensure
    return unless source
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
  end

  def test_register_handles_errors
    @ref = REF
    obsrvr = observer { |_,_,_| }
    assert_raises(ArgumentError) {
      register(nil, to_receive: KAXWindowCreatedNotification)
    }
    assert_raises(ArgumentError) {
      register(observer, to_receive: nil)
    }
    @ref = nil
    assert_raises(ArgumentError) {
      register(observer, to_receive: KAXWindowCreatedNotification)
    }
  end

  def test_unregister_handles_errors
    @ref = REF
    assert_raises(ArgumentError) {
      unregister(nil, from_receiving: KAXWindowCreatedNotification)
    }
    assert_raises(ArgumentError) {
      unregister(observer, from_receiving: nil)
    }
    @ref = nil
    assert_raises ArgumentError do
      unregister(observer, from_receiving: KAXWindowCreatedNotification)
    end
  end

  def test_enabled?
    assert enabled?
    # @todo I guess that's good enough?
  end

  def test_pid_for_gets_pid
    @ref = REF
    assert_equal PID, pid
    @ref = window
    assert_equal PID, pid
  end

  def test_pid_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { pid }
  end

  def test_system_wide
    assert_equal AXUIElementCreateSystemWide(), system_wide
  end

  def test_set_timeout_for
    @ref = REF
    assert_equal 10, set_timeout_to(10)
    assert_equal 0,  set_timeout_to(0)
  end

  def test_set_timeout_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { set_timeout_to(10) }
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
    def self.pid
      NSRunningApplication
        .runningApplicationsWithBundleIdentifier('com.apple.finder')
        .first.processIdentifier
    end
       assert_error [KAXErrorCannotComplete],
      should_raise: RuntimeError,
    with_fragments: [/An unspecified error/, app, /:\(/]

    def self.pid; false end
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

  # trivial but important for backwards compat with Snow Leopard
  def test_identifier_const
    assert_equal 'AXIdentifier', KAXIdentifierAttribute
  end

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
