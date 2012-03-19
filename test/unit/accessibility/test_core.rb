# -*- coding: utf-8 -*-
class TestAccessibilityCore < MiniTest::Unit::TestCase
  include Accessibility::Core

  def ref
    @@ref ||= Regexp.new(Regexp.escape(REF.description))
  end

  def window
    @@window ||= value_of KAXMainWindowAttribute, for: REF
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
        value_of(KAXTitleAttribute, for: item) == 'Yes'
      end
    end
  end

  def web_area
    @@web_area ||= children_for(children_for(window).find do |item|
      if role_for(item) == 'AXScrollArea'
        value_of(KAXDescriptionAttribute, for: item) == 'Test Web Area'
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
    assert_equal 'AXElementsTester', value_of(KAXTitleAttribute,  for: REF)
    assert_equal false,              value_of(KAXHiddenAttribute, for: REF)
    assert_kind_of CGSize,           value_of(KAXSizeAttribute, for: window)
  end

  def test_attr_value_is_nil_when_no_value_error_occurs
    assert_nil value_of(KAXGrowAreaAttribute, for: window)
  end

  def test_attr_value_handles_errors
    assert_raises ArgumentError do
      value_of('MADEUPATTRIBUTE', for: REF)
    end
  end



  def test_attrs_value_is_correct
    assert_equal ['AXElementsTester'], values_of([KAXTitleAttribute],  for: REF)
    assert_equal [false],              values_of([KAXHiddenAttribute], for: REF)
    assert_equal [CGPoint, CGSize],
      values_of([KAXPositionAttribute, KAXSizeAttribute], for: window).map(&:class)
  end

  def test_attrs_value_fills_in_nils_when_no_value_error_occurs
    assert_nil values_of([KAXSubroleAttribute, KAXRoleAttribute], for: web_area).first
    assert_nil values_of([KAXRoleAttribute, KAXSubroleAttribute], for: web_area)[1]
  end

  def test_attrs_value_handles_errors
    assert_raises ArgumentError do
      values_of(['MADEUPATTRIBUTE'], for: nil)
    end
    assert_raises ArgumentError do
      values_of([], for: REF)
    end
  end



  def test_subrole_macro
    assert_equal KAXStandardWindowSubrole, subrole_for(window)
    assert_equal nil,                      subrole_for(web_area)
  end

  def test_role_macro
    assert_equal KAXApplicationRole, role_for(REF)
    assert_equal KAXWindowRole,      role_for(window)
  end

  def test_children_for_macro
    assert_equal value_of(KAXChildrenAttribute, for: REF), children_for(REF)
    assert_equal value_of(KAXChildrenAttribute, for: slider), children_for(slider)
  end

  def test_value_for_macro
    assert_equal value_of(KAXValueAttribute, for: check_box), value_for(check_box)
    assert_equal value_of(KAXValueAttribute, for: slider), value_for(slider)
  end



  def test_attr_writable_correct_values
    assert writable?(KAXMainAttribute, for: window)
    refute writable?(KAXTitleAttribute, for: REF)
  end

  def test_attr_writable_false_for_no_value_cases
    skip 'I am not aware of how to create such a case...'
    # refute writable?(KAXChildrenAttribute, for: REF)
  end

  def test_attr_writable_handles_errors
    assert_raises ArgumentError do
      writable? 'FAKE', for: REF
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

    string = ''
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
    attr =   value_of KAXStringForRangeParameterizedAttribute,
           for_param: CFRange.new(0, 5).to_axvalue,
                 for: static_text

    assert_equal 'AXEle', attr

    attr =   value_of KAXAttributedStringForRangeParameterizedAttribute,
           for_param: CFRange.new(0, 5).to_axvalue,
                 for: static_text

    assert_kind_of NSAttributedString, attr
    assert_equal 'AXEle', attr.string

    # Should add a test case to test the no value case, but it will have
    # to be fabricated in the test app.
  end

  def test_param_attr_handles_errors
    assert_raises ArgumentError do # has no param attrs
        value_of KAXStringForRangeParameterizedAttribute,
      for_param: CFRange.new(0, 10).to_axvalue,
            for: REF
    end

    assert_raises ArgumentError do # invalid element
        value_of KAXStringForRangeParameterizedAttribute,
      for_param: CFRange.new(0, 10).to_axvalue,
            for: nil
    end

    assert_raises ArgumentError do # invalid argument
        value_of KAXStringForRangeParameterizedAttribute,
      for_param: CFRange.new(0, 10),
            for: REF
     end

    # Need to test the other failure cases eventually...
  end



  ##
  # Kind of a bad test right now because the method itself
  # lacks certain functionality that needs to be added...

  def test_element_at_point_gets_dude
    point   = value_of KAXPositionAttribute, for: button
    element = element_at point, for: REF
    assert_equal button, element, "#{button.inspect} and #{element.inspect}"

    # also check the system object
  end

  def test_element_at_point_handles_errors
    assert_raises ArgumentError do
      element_at [10,10], for: nil
    end

    # Should test the other cases as well...
  end



  def test_observer_for
    assert_equal AXObserverGetTypeID(), CFGetTypeID(observer_for(PID) { })
  end

  def test_observer_for_handles_errors
    assert_raises TypeError do
      observer_for nil do end
    end
    assert_raises ArgumentError do
      observer_for PID
    end
  end



  def test_run_loop_source
    observer = observer_for(PID) { |_,_,_,_| }
    assert_equal CFRunLoopSourceGetTypeID(),
      CFGetTypeID(run_loop_source_for(observer))
  end



  def test_notification_registration_and_unregistration
    observer = observer_for(PID) { |_,_,_,_| }
    assert   register(observer,     to_receive: KAXWindowCreatedNotification, from: REF)
    assert unregister(observer, from_receiving: KAXWindowCreatedNotification, from: REF)
  end

  def test_notification_registers_everything_correctly # integration
    callback = Proc.new do |observer, element, notif, ctx|
      @notif_triple = [observer, element, notif]
    end
    observer = observer_for PID, &callback
    register observer, to_receive: 'Cheezburger', from: yes_button

    source = run_loop_source_for observer
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)

    perform KAXPressAction, for: yes_button
    spin_run_loop

    assert_equal [observer, yes_button, 'Cheezburger'], @notif_triple

  ensure
    return
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
  end

  def test_notification_registrations_handle_errors
    observer = observer_for(PID) { |_,_,_,_| }

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



  def test_system_wide
    assert_equal AXUIElementCreateSystemWide(), system_wide
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
    unless RUNNING_COMPILED
      assert_match @@meth, e.backtrace.first, e.backtrace
    end
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
       with_fragments: [/An unspecified error/, ref, /:\(/]

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


class TestCoreExtensionsForCore < MiniTest::Unit::TestCase
  include Accessibility::Core

  def test_to_axvalue_wraps_things
    # point_makes_a_value
    value = CGPointZero.to_axvalue
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(value, 1, ptr)
    assert_equal CGPointZero, ptr[0]

    # size_makes_a_value
    value = CGSizeZero.to_axvalue
    ptr   = Pointer.new CGSize.type
    AXValueGetValue(value, 2, ptr)
    assert_equal CGSizeZero, ptr[0]

    # rect_makes_a_value
    value = CGRectZero.to_axvalue
    ptr   = Pointer.new CGRect.type
    AXValueGetValue(value, 3, ptr)
    assert_equal CGRectZero, ptr[0]

    # range_makes_a_value
    range = CFRange.new(5, 4)
    value = range.to_axvalue
    ptr   = Pointer.new CFRange.type
    AXValueGetValue(value, 4, ptr)
    assert_equal range, ptr[0]
  end

  def test_to_axvalue_on_non_boxes
    obj = Object.new
    assert_respond_to obj, :to_axvalue
    assert_equal obj.self, obj.to_axvalue
  end

  def test_to_axvalue_raises_for_unsupported_boxes
    assert_raises NotImplementedError do
      NSEdgeInsets.new.to_axvalue
    end
  end

  def test_to_value
    assert_equal CGPointZero, CGPointZero.to_axvalue.to_value
    assert_equal CGSizeMake(10,10), CGSizeMake(10,10).to_axvalue.to_value
  end

  def test_to_value_on_non_boxes
    obj = Object.new
    assert_respond_to obj, :to_value
    assert_equal obj.self, obj.to_value
  end

  # trivial but important for backwards compat with Snow Leopard
  def test_identifier_const
    assert Object.const_defined? :KAXIdentifierAttribute
    assert_equal 'AXIdentifier', KAXIdentifierAttribute
  end

  def test_to_point
    assert_equal CGPointZero, CGPointZero.to_point
    assert_equal CGPointMake(2,3), CGPointMake(2,3).to_point

    assert_instance_of CGPoint, [1, 1].to_point
    assert_equal [2,3], [2,3].to_point.to_a
    assert_equal CGPoint.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_point
  end

  def test_to_size
    assert_instance_of CGSize, [1, 1].to_size
    assert_equal [2,3], [2,3].to_size.to_a
    assert_equal CGSize.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_size
  end

  def test_to_rect
    assert_instance_of CGRect, [1, 1, 1, 1].to_rect
    assert_equal [2,3,4,5], [2,3,4,5].to_rect.to_a.map(&:to_a).flatten
    assert_equal CGRectMake(6,7,8,9), [6,7,8,9,10].to_rect
  end

end
