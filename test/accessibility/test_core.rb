# -*- coding: utf-8 -*-
class TestAccessibilityCore < MiniTest::Unit::TestCase
  include Accessibility::Core

  def ref
    @@ref ||= Regexp.new(Regexp.escape(REF.description))
  end

  def window
    @@window ||= attr KAXMainWindowAttribute, for: REF
  end

  def children
    @@chidlren ||= children_for window
  end

  def child name
    children.find { |item| role_for(item) == name }
  end

  def slider;      @@slider      ||= child KAXSliderRole;     end
  def check_box;   @@check_box   ||= child KAXCheckBoxRole;   end
  def search_box;  @@search_box  ||= child KAXTextFieldRole;  end
  def button;      @@button      ||= child KAXButtonRole;     end
  def static_text; @@static_text ||= child KAXStaticTextRole; end

  def yes_button
    @@yes_button ||= children.find do |item|
      if role_for(item) == KAXButtonRole
        attr(KAXTitleAttribute, for: item) == 'Yes'
      end
    end
  end

  def web_area
    @@web_area ||= children_for(children_for(window).find do |item|
      if role_for(item) == 'AXScrollArea'
        attr(KAXDescriptionAttribute, for: item) == 'Test Web Area'
      end
    end).first
  end



  ##
  # AFAICT every accessibility object **MUST** have attributes, so
  # there are no tests to check what happens when they do not exist;
  # though I am quite sure that AXElements will explode.

  def test_attrs_is_array_of_strings
    attrs = attrs_for REF

    refute_empty attrs

    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXRoleDescriptionAttribute

    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute
  end

  def test_attrs_handles_errors
    assert_raises ArgumentError do
      attrs_for nil
    end

    # I'm having a hard time trying to figure out how to test the other
    # failure cases...
  end



  def test_size_of
    assert_equal children_for(REF).size, size_of(KAXChildrenAttribute, for: REF)
    assert_equal 0,                      size_of(KAXChildrenAttribute, for: button)
  end

  def test_attr_count_handles_errors
    assert_raises ArgumentError do
      size_of 'pie', for: REF
    end

    assert_raises ArgumentError do
      size_of KAXChildrenAttribute, for: nil
    end

    # Not sure how to trigger other failure cases reliably...
  end



  def test_attr_value_is_correct
    assert_equal 'AXElementsTester', attr(KAXTitleAttribute,  for: REF)
    assert_equal false,              attr(KAXHiddenAttribute, for: REF)
    assert_equal AXValueGetTypeID(), CFGetTypeID(attr(KAXSizeAttribute, for: window))
  end

  def test_attr_value_is_nil_when_no_value_error_occurs
    assert_nil attr(KAXGrowAreaAttribute, for: window)
  end

  def test_attr_value_handles_errors
    assert_raises ArgumentError do
      attr('MADEUPATTRIBUTE', for: REF)
    end
  end



  def test_attrs_value_is_correct
    assert_equal ['AXElementsTester'], attrs([KAXTitleAttribute],  for: REF)
    assert_equal [false],              attrs([KAXHiddenAttribute], for: REF)
    assert_equal [CGPoint.ax_value, CGSize.ax_value],
      attrs([KAXPositionAttribute, KAXSizeAttribute], for: window).map { |x| AXValueGetType(x) }
  end

  def test_attrs_value_fills_in_nils_when_no_value_error_occurs
    assert_nil attrs([KAXSubroleAttribute, KAXRoleAttribute], for: web_area).first
    assert_nil attrs([KAXRoleAttribute, KAXSubroleAttribute], for: web_area).second
  end

  def test_attrs_value_handles_errors
    assert_raises ArgumentError do
      attrs(['MADEUPATTRIBUTE'], for: nil)
    end
    assert_raises ArgumentError do
      attrs(nil, for: REF)
    end
    assert_raises ArgumentError do
      attrs([], for: REF)
    end
  end



  def test_role_pair_macro
    assert_equal [KAXStandardWindowSubrole, KAXWindowRole], role_pair_for(window)
    assert_equal [nil, 'AXWebArea'],                        role_pair_for(web_area)
  end

  def test_role_macro
    assert_equal KAXApplicationRole, role_for(REF)
    assert_equal KAXWindowRole,      role_for(window)
  end

  def test_children_for_macro
    assert_equal attr(KAXChildrenAttribute, for: REF), children_for(REF)
    assert_equal attr(KAXChildrenAttribute, for: slider), children_for(slider)
  end

  def test_value_for_macro
    assert_equal attr(KAXValueAttribute, for: check_box), value_for(check_box)
    assert_equal attr(KAXValueAttribute, for: slider), value_for(slider)
  end



  def test_writable_attr_correct_values
    assert writable_attr?(KAXMainAttribute, for: window)
    refute writable_attr?(KAXTitleAttribute, for: REF)
  end

  def test_writable_attr_false_for_no_value_cases
    skip 'I am not aware of how to create such a case...'
    # refute writable_attr?(KAXChildrenAttribute, for: REF)
  end

  def test_writable_attr_handles_errors
    assert_raises ArgumentError do
      writable_attr? 'FAKE', for: REF
    end

    # Not sure how to test other cases...
  end



  def test_set_attr_on_slider
    [25, 75, 50].each do |value|
      set KAXValueAttribute, to: value, for: slider
      assert_equal value, value_for(slider)
    end
  end

  def test_set_attr_on_text_field
    [Time.now.to_s, ''].each do |value|
      set KAXValueAttribute, to: value, for: search_box
      assert_equal value, value_for(search_box)
    end
  end

  def test_set_attr_returns_setting_value
    string = 'The answer to life, the universe, and everything...'
    result = set KAXValueAttribute, to: string, for: search_box
    assert_equal string, result

    string = ::EMPTY_STRING
    result = set KAXValueAttribute, to: string, for: search_box
    assert_equal string, result
  end

  def test_set_attr_handles_errors
    assert_raises ArgumentError do
      set 'FAKE', to: true, for: REF
    end

    # Not sure how to test other failure cases...
  end



  def test_actions_is_an_array
    assert_empty                                           actions_for(REF)
    assert_equal [KAXPressAction],                         actions_for(yes_button)
    assert_equal [KAXIncrementAction, KAXDecrementAction], actions_for(slider)
  end

  def test_actions_handles_errors
    assert_raises ArgumentError do
      actions_for nil
    end

    # Not sure how to test other failure cases...
  end

  def test_action_triggers_checking_a_check_box
    2.times do # twice so it should be back where it started
      value = value_for check_box
      perform KAXPressAction, for: check_box
      refute_equal value, value_for(check_box)
    end
  end

  def test_action_triggers_sliding_the_slider
    value = value_for slider
    perform KAXIncrementAction, for: slider
    assert value_for(slider) > value

    value = value_for slider
    perform KAXDecrementAction, for: slider
    assert value_for(slider) < value
  end

  def test_action_handles_errors
    assert_raises ArgumentError do
      perform KAXPressAction, for: nil
    end

    assert_raises ArgumentError do
      perform nil, for: REF
    end
  end



  ##
  # The keyboard simulation stuff is a bit weird...

  def test_post_events
    events = [[0x56,true], [0x56,false], [0x54,true], [0x54,false]]
    string = '42'

    set KAXFocusedAttribute, to: true, for: search_box
    post events, to: REF
    assert_equal string, value_for(search_box)

  ensure # reset for next test
    button = children_for(search_box).find { |x|
      role_for(x) == KAXButtonRole
    }
    perform KAXPressAction, for: button
  end

  def test_post_events_handles_errors
    assert_raises ArgumentError do
      post [[56, true], [56, false]], to: nil
    end
  end



  def test_param_attrs
    assert_empty param_attrs_for REF

    attrs = param_attrs_for static_text
    assert_includes attrs, KAXStringForRangeParameterizedAttribute
    assert_includes attrs, KAXLineForIndexParameterizedAttribute
    assert_includes attrs, KAXBoundsForRangeParameterizedAttribute
  end

  def test_param_attrs_handles_errors
    assert_raises ArgumentError do # invalid
      param_attrs_for nil
    end

    # Need to test the other failure cases eventually...
  end



  def test_param_attr_fetching
    attr = param_attr KAXStringForRangeParameterizedAttribute,
           for_param: CFRange.new(0, 5).to_axvalue,
                 for: static_text

    assert_equal 'AXEle', attr

    attr = param_attr KAXAttributedStringForRangeParameterizedAttribute,
           for_param: CFRange.new(0, 5).to_axvalue,
                 for: static_text

    assert_kind_of NSAttributedString, attr
    assert_equal 'AXEle', attr.string

    # Should add a test case to test the no value case, but it will have
    # to be fabricated in the test app.
  end

  def test_param_attr_handles_errors
    assert_raises ArgumentError do # has no param attrs
      param_attr KAXStringForRangeParameterizedAttribute,
      for_param: CFRange.new(0, 10).to_axvalue,
            for: REF
    end

    assert_raises ArgumentError do # invalid element
      param_attr KAXStringForRangeParameterizedAttribute,
      for_param: CFRange.new(0, 10).to_axvalue,
            for: nil
    end

    assert_raises ArgumentError do # invalid argument
      param_attr KAXStringForRangeParameterizedAttribute,
      for_param: CFRange.new(0, 10),
            for: REF
     end

    # Need to test the other failure cases eventually...
  end



  ##
  # Kind of a bad test right now because the method itself
  # lacks certain functionality that needs to be added...

  def test_element_at_point_gets_dude
    point = attr KAXPositionAttribute, for: button
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(point, KAXValueCGPointType, ptr)
    point = ptr[0]
    element = element_at_point point.x, and: point.y, for: REF
    assert_equal button, element

    # also check the system object
  end

  def test_element_at_point_handles_errors
    assert_raises ArgumentError do
      element_at_point 10, and: 10, for: nil
    end

    # Should test the other cases as well...
  end



  def observer_callback observer, element, notif, context
    @notif_triple = [observer, element, notif, context]
  end

  def test_observer_for
    assert_equal AXObserverGetTypeID(),
      CFGetTypeID(observer_for(PID, calling: method(:observer_callback)))

    observer = observer_for PID, calling: nil do |herp, derp, erp, burp| end
    assert_equal AXObserverGetTypeID(), CFGetTypeID(observer)
  end

  def test_observer_for_handles_errors
    assert_raises TypeError do
      observer_for nil, calling: method(:observer_callback)
    end
    assert_raises ArgumentError do
      observer_for PID, calling: nil
    end
  end



  def test_run_loop_source
    observer = observer_for(PID, calling: method(:observer_callback))
    assert_equal CFRunLoopSourceGetTypeID(),
      CFGetTypeID(run_loop_source_for(observer))
  end



  def test_notification_registration
    observer = observer_for(PID, calling: method(:observer_callback))
    assert   register(observer,     to_receive: KAXWindowCreatedNotification, from: REF)
    assert unregister(observer, from_receiving: KAXWindowCreatedNotification, from: REF)
  end

  def test_notification_registrations_handle_errors
    observer = observer_for(PID, calling: method(:observer_callback))

    assert_raises ArgumentError do
      register(nil, to_receive: KAXWindowCreatedNotification, from: REF)
    end
    assert_raises ArgumentError do
      register(observer, to_receive: nil, from: REF)
    end
    assert_raises ArgumentError do
      register(observer, to_receive: KAXWindowCreatedNotification, from: nil)
    end
    assert_raises ArgumentError do
      unregister(nil, from_receiving: KAXWindowCreatedNotification, from: REF)
    end
    assert_raises ArgumentError do
      unregister(observer, from_receiving: nil, from: REF)
    end
    assert_raises ArgumentError do
      unregister(observer, from_receiving: KAXWindowCreatedNotification, from: nil)
    end
  end



  def test_unwrap
    assert_equal CGPointZero, unwrap(wrap(CGPointZero))
    assert_equal CGSizeMake(10,10), unwrap(wrap(CGSizeMake(10,10)))
  end

  def test_wrap
    # point_makes_a_value
    value = wrap CGPointZero
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(value, 1, ptr)
    assert_equal CGPointZero, ptr[0]

    # size_makes_a_value
    value = wrap CGSizeZero
    ptr   = Pointer.new CGSize.type
    AXValueGetValue(value, 2, ptr)
    assert_equal CGSizeZero, ptr[0]

    # rect_makes_a_value
    value = wrap CGRectZero
    ptr   = Pointer.new CGRect.type
    AXValueGetValue(value, 3, ptr)
    assert_equal CGRectZero, ptr[0]

    # range_makes_a_value
    range = CFRange.new(5, 4)
    value = wrap range
    ptr   = Pointer.new CFRange.type
    AXValueGetValue(value, 4, ptr)
    assert_equal range, ptr[0]
  end



  def test_enabled?
    assert enabled?
    # @todo I guess that's good enough?
  end



  def test_app_for_pid
    # @note Should call CFEqual() under the hood, which is what we want
    assert_equal REF, application_for(PID)
  end

  def test_app_for_pid_raises_for_bad_pid
    assert_raises ArgumentError do
      application_for 0
    end

    assert_raises ArgumentError do
      application_for 2
    end
  end



  def test_pid_for_gets_pid
    assert_equal PID, pid_for(REF)
    assert_equal PID, pid_for(window)
  end

  def test_pid_for_handles_errors
    assert_raises ArgumentError do
      pid_for nil
    end
  end



  def test_spin_runloop
    @run_loop_ran = false
    def run_loop_test
      @run_loop_ran = true
    end

    performSelector 'run_loop_test', afterDelay: 0

    assert @run_loop_ran
  end



  def test_set_timeout
    assert_equal 10, set_timeout_to(10, for: REF)
    assert_equal 0,  set_timeout_to(0, for: REF)
  end

  def test_set_timeout_handles_errors
    assert_raises ArgumentError do
      set_timeout_to 10, for: nil
    end
  end



  def error_handler_test args, should_raise: klass, with_fragments: msgs
    @@meth ||= Regexp.new "`#{__method__}'$"
    handle_error *args
  rescue Exception => e
    assert_instance_of klass, e, e.inspect
    assert_match @@meth, e.backtrace.first, e.backtrace
    msgs.each do |msg|
      assert_match msg, e.message
    end
  end

  def test_has_failsafe_exception
    error_handler_test [99],
         should_raise: RuntimeError,
       with_fragments: [/never reach this line/, /99/]
  end

  def test_failure
    error_handler_test [KAXErrorFailure, REF],
         should_raise: RuntimeError,
       with_fragments: [/system failure/, ref]
  end

  def test_illegal_argument
    skip 'OMG, PLEASE NO'
  end

  def test_invalid_element
    error_handler_test [KAXErrorInvalidUIElement, REF],
         should_raise: ArgumentError,
       with_fragments: [/no longer a valid reference/, ref]
  end

  def test_invalid_observer
    error_handler_test [KAXErrorInvalidUIElementObserver, REF, :pie, :cake],
         should_raise: ArgumentError,
       with_fragments: [/no longer a valid observer/, /or was never valid/, ref, /cake/]
  end

  def test_cannot_complete
    def self.pid_for lol
      NSRunningApplication
        .runningApplicationsWithBundleIdentifier('com.apple.finder')
        .first.processIdentifier
    end
    error_handler_test [KAXErrorCannotComplete, REF],
         should_raise: RuntimeError,
       with_fragments: [/Some unspecified error/, ref, /:\(/]

    def self.pid_for lol; false; end
    error_handler_test [KAXErrorCannotComplete, nil],
         should_raise: RuntimeError,
       with_fragments: [/Application for pid/, /Maybe it crashed\?/]
  end

  def test_attr_unsupported
    error_handler_test [KAXErrorAttributeUnsupported, REF, :cake],
         should_raise: ArgumentError,
       with_fragments: [/does not have/, /:cake attribute/, ref]
  end

  def test_action_unsupported
    error_handler_test [KAXErrorActionUnsupported, REF, :pie],
         should_raise: ArgumentError,
       with_fragments: [/does not have/, /:pie action/, ref]
  end

  def test_notif_unsupported
    error_handler_test [KAXErrorNotificationUnsupported, REF, :cheese],
         should_raise: ArgumentError,
       with_fragments: [/does not support/, /:cheese notification/, ref]
  end

  def test_not_implemented
    error_handler_test [KAXErrorNotImplemented, REF],
         should_raise: NotImplementedError,
       with_fragments: [/does not work with AXAPI/, ref]
  end

  def test_notif_registered
    error_handler_test [KAXErrorNotificationAlreadyRegistered, REF, :lamp],
         should_raise: ArgumentError,
       with_fragments: [/already registered/, /:lamp/, ref]
  end

  def test_notif_not_registered
    error_handler_test [KAXErrorNotificationNotRegistered, REF, :peas],
         should_raise: RuntimeError,
       with_fragments: [/not registered/, /:peas/, ref]
  end

  def test_api_disabled
    error_handler_test [KAXErrorAPIDisabled],
         should_raise: RuntimeError,
       with_fragments: [/AXAPI has been disabled/]
  end

  def test_param_attr_unsupported
    error_handler_test [KAXErrorParameterizedAttributeUnsupported, REF, :oscar],
         should_raise: ArgumentError,
       with_fragments: [/does not have/, /:oscar parameterized attribute/, ref]
  end

  def test_not_enough_precision
    error_handler_test [KAXErrorNotEnoughPrecision],
         should_raise: RuntimeError,
       with_fragments: [/not enough precision/, '¯\(°_o)/¯']
  end

end
