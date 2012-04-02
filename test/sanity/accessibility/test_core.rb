# -*- coding: utf-8 -*-

require 'test/helper'
require 'accessibility/core'


class TestAccessibilityCore < MiniTest::Unit::TestCase
  include Accessibility::Core

  def set_invalid_ref
    bye_button # guarantee that it is cached
    @@dead ||= (@ref = no_button; perform KAXPressAction)
    @ref     = bye_button
  end

  # def app_description
  #   @@app_description ||= Regexp.new(Regexp.escape(REF.description))
  # end

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

  def slider;     @@slider     ||= child KAXSliderRole;      end
  def check_box;  @@check_box  ||= child KAXCheckBoxRole;    end
  def pop_up;     @@pop_up     ||= child KAXPopUpButtonRole; end
  def search_box; @@search_box ||= child KAXTextFieldRole;   end
  # def static_text; @@static_text ||= child KAXStaticTextRole; end

  def yes_button
    @@yes_button ||= child(KAXButtonRole) { attribute(KAXTitleAttribute) == 'Yes' }
  end

  def bye_button
    @@bye_button ||= child(KAXButtonRole) { attribute(KAXTitleAttribute) == 'Bye!' }
  end

  def no_button
    @@no_button ||= child(KAXButtonRole) { attribute(KAXTitleAttribute) == 'No' }
  end

  def web_area
    @@web_area ||= (
      child("AXScrollArea") { attribute("AXDescription") == 'Test Web Area' }
      children.first
    )
  end

  def text_area
    @@text_area ||= (child("AXScrollArea") do
        attributes.include?(KAXIdentifierAttribute) &&
          attribute(KAXIdentifierAttribute) == 'Text Area'
      end
      children.first)
  end



  ##
  # AFAICT every accessibility object **MUST** have attributes, so
  # there are no tests to check what happens when they do not exist;
  # though I am quite sure that AXElements will raise an exception.

  def test_attr_names_is_strings
    @ref = REF
    attrs = attributes

    refute_empty attrs
    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute
  end

  def test_attr_names_is_empty_for_dead_elements
    set_invalid_ref
    assert_empty attributes
  end

  def test_attrs_handles_errors
    @ref = nil
    assert_raises(ArgumentError) { attributes }
  end

  def test_attr_correctness
    @ref = window
    assert_equal 'AXElementsTester',  attribute(KAXTitleAttribute  )
    assert_equal false,               attribute(KAXFocusedAttribute)
    assert_equal CGSizeMake(555,483), attribute(KAXSizeAttribute   )
    assert_equal REF,                 attribute(KAXParentAttribute )
    assert_equal 10..19,              attribute("AXPie"            )
  end

  def test_attr_is_nil_when_no_value_or_dead
    @ref = window
    assert_nil attribute(KAXGrowAreaAttribute)
    set_invalid_ref
    assert_nil attribute(KAXRoleAttribute)
  end

  def test_attr_value_handles_errors
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

  def test_attr_writable
    @ref = REF
    refute writable? KAXTitleAttribute
    @ref = window
    assert writable? KAXMainAttribute
  end

  def test_attr_writable_false_for_dead_cases
    set_invalid_ref
    refute writable? KAXRoleAttribute
  end

  def test_attr_writable_handles_errors
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

#   def test_post_events_to
#     events = [[0x56,true], [0x56,false], [0x54,true], [0x54,false]]
#     string = '42'

#     set KAXFocusedAttribute, to: true, for: search_box
#     post events, to: REF
#     assert_equal string, value_for(search_box)

#   ensure # reset for next test
#     button = children_for(search_box).find { |x|
#       role_for(x) == KAXButtonRole
#     }
#     perform KAXPressAction, for: button
#   end

#   def test_post_events_to_handles_errors
#     assert_raises ArgumentError do
#       post [[56, true], [56, false]], to: nil
#     end
#   end

#   def test_post_events_calls_post_events_to
#     klass = Class.new
#     klass.send :include, Accessibility::Core

#     events = element = nil
#     klass.send :define_method, :'post:to:' do |arg1,arg2|
#       events, element = arg1, arg2
#     end

#     klass.new.send :post, [:herp, :derp]
#     assert_equal [:herp, :derp], events
#     assert_equal system_wide, element
#   end


#   def test_param_attrs
#     assert_empty param_attrs_for REF

#     attrs = param_attrs_for static_text
#     assert_includes attrs, KAXStringForRangeParameterizedAttribute
#     assert_includes attrs, KAXLineForIndexParameterizedAttribute
#     assert_includes attrs, KAXBoundsForRangeParameterizedAttribute
#   end

#   def test_param_attrs_handles_errors
#     assert_raises ArgumentError do # invalid
#       param_attrs_for nil
#     end

#     # Need to test the other failure cases eventually...
#   end



#   def test_param_attr_fetching
#     attr =   value_of KAXStringForRangeParameterizedAttribute,
#            for_param: CFRange.new(0, 5).to_axvalue,
#                  for: static_text

#     assert_equal 'AXEle', attr

#     attr =   value_of KAXAttributedStringForRangeParameterizedAttribute,
#            for_param: CFRange.new(0, 5).to_axvalue,
#                  for: static_text

#     assert_kind_of NSAttributedString, attr
#     assert_equal 'AXEle', attr.string

#     # Should add a test case to test the no value case, but it will have
#     # to be fabricated in the test app.
#   end

#   def test_param_attr_handles_errors
#     assert_raises ArgumentError do # has no param attrs
#         value_of KAXStringForRangeParameterizedAttribute,
#       for_param: CFRange.new(0, 10).to_axvalue,
#             for: REF
#     end

#     assert_raises ArgumentError do # invalid element
#         value_of KAXStringForRangeParameterizedAttribute,
#       for_param: CFRange.new(0, 10).to_axvalue,
#             for: nil
#     end

#     assert_raises ArgumentError do # invalid argument
#         value_of KAXStringForRangeParameterizedAttribute,
#       for_param: CFRange.new(0, 10),
#             for: REF
#      end

#     # Need to test the other failure cases eventually...
#   end



#   ##
#   # Kind of a bad test right now because the method itself
#   # lacks certain functionality that needs to be added...

#   def test_element_at_point_for_gets_dude
#     point   = value_of KAXPositionAttribute, for: button
#     element = element_at point, for: REF
#     assert_equal button, element, "#{button.inspect} and #{element.inspect}"

#     # also check the system object
#   end

#   def test_element_at_point_for_handles_errors
#     assert_raises ArgumentError do
#       element_at [10,10], for: nil
#     end

#     # Should test the other cases as well...
#   end

#   def test_element_at_point_delegates
#     klass = Class.new
#     klass.send :include, Accessibility::Core

#     point = element = nil
#     klass.send :define_method, :'element_at:for:' do |arg1,arg2|
#       point, element = arg1, arg2
#     end

#     klass.new.send :element_at, :upper_right
#     assert_equal :upper_right, point
#     assert_equal system_wide, element
#   end



#   def test_observer_for
#     assert_equal AXObserverGetTypeID(), CFGetTypeID(observer_for(PID) { })
#   end

#   def test_observer_for_handles_errors
#     assert_raises TypeError do
#       observer_for nil do end
#     end
#     assert_raises ArgumentError do
#       observer_for PID
#     end
#   end



#   def test_run_loop_source
#     observer = observer_for(PID) { |_,_,_,_| }
#     assert_equal CFRunLoopSourceGetTypeID(),
#       CFGetTypeID(run_loop_source_for(observer))
#   end



#   def test_notification_registration_and_unregistration
#     observer = observer_for(PID) { |_,_,_,_| }
#     assert   register(observer,     to_receive: KAXWindowCreatedNotification, from: REF)
#     assert unregister(observer, from_receiving: KAXWindowCreatedNotification, from: REF)
#   end

#   def test_notification_registers_everything_correctly # integration
#     callback = Proc.new do |observer, element, notif, ctx|
#       @notif_triple = [observer, element, notif]
#     end
#     observer = observer_for PID, &callback
#     register observer, to_receive: 'Cheezburger', from: yes_button

#     source = run_loop_source_for observer
#     CFRunLoopAddSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)

#     perform KAXPressAction, for: yes_button
#     spin_run_loop

#     assert_equal [observer, yes_button, 'Cheezburger'], @notif_triple

#   ensure
#     return
#     CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
#   end

#   def test_notification_registrations_handle_errors
#     observer = observer_for(PID) { |_,_,_,_| }

#     assert_raises ArgumentError do
#       register(nil, to_receive: KAXWindowCreatedNotification, from: REF)
#     end
#     assert_raises ArgumentError do
#       register(observer, to_receive: nil, from: REF)
#     end
#     assert_raises ArgumentError do
#       register(observer, to_receive: KAXWindowCreatedNotification, from: nil)
#     end
#     assert_raises ArgumentError do
#       unregister(nil, from_receiving: KAXWindowCreatedNotification, from: REF)
#     end
#     assert_raises ArgumentError do
#       unregister(observer, from_receiving: nil, from: REF)
#     end
#     assert_raises ArgumentError do
#       unregister(observer, from_receiving: KAXWindowCreatedNotification, from: nil)
#     end
#   end



#   def test_enabled?
#     assert enabled?
#     # @todo I guess that's good enough?
#   end



#   def test_app_for_pid
#     # @note Should call CFEqual() under the hood, which is what we want
#     assert_equal REF, application_for(PID)
#   end

#   def test_app_for_pid_raises_for_bad_pid
#     assert_raises ArgumentError do
#       application_for 0
#     end

#     assert_raises ArgumentError do
#       application_for 2
#     end
#   end



#   def test_pid_for_gets_pid
#     assert_equal PID, pid_for(REF)
#     assert_equal PID, pid_for(window)
#   end

#   def test_pid_for_handles_errors
#     assert_raises ArgumentError do
#       pid_for nil
#     end
#   end



#   def test_system_wide
#     assert_equal AXUIElementCreateSystemWide(), system_wide
#   end



#   def test_spin_runloop
#     @run_loop_ran = false
#     def run_loop_test
#       @run_loop_ran = true
#     end

#     performSelector 'run_loop_test', afterDelay: 0

#     assert @run_loop_ran
#   end



#   def test_set_timeout_for
#     assert_equal 10, set_timeout_to(10, for: REF)
#     assert_equal 0,  set_timeout_to(0, for: REF)
#   end

#   def test_set_timeout_handles_errors
#     assert_raises ArgumentError do
#       set_timeout_to 10, for: nil
#     end
#   end

#   def test_set_timeout
#     assert_equal 10, set_timeout_to(10)
#     assert_equal 0, set_timeout_to(0)
#   end



#   def error_handler_test args, should_raise: klass, with_fragments: msgs
#     @@meth ||= Regexp.new "`#{__method__}'$"
#     handle_error *args
#   rescue Exception => e
#     assert_instance_of klass, e, e.inspect
#     unless RUNNING_COMPILED
#       assert_match @@meth, e.backtrace.first, e.backtrace
#     end
#     msgs.each do |msg|
#       assert_match msg, e.message
#     end
#   end

#   def test_has_failsafe_exception
#     error_handler_test [99],
#          should_raise: RuntimeError,
#        with_fragments: [/never reach this line/, /99/]
#   end

#   def test_failure
#     error_handler_test [KAXErrorFailure, REF],
#          should_raise: RuntimeError,
#        with_fragments: [/system failure/, ref]
#   end

#   def test_illegal_argument
#     skip 'OMG, PLEASE NO'
#   end

#   def test_invalid_element
#     error_handler_test [KAXErrorInvalidUIElement, REF],
#          should_raise: ArgumentError,
#        with_fragments: [/no longer a valid reference/, ref]
#   end

#   def test_invalid_observer
#     error_handler_test [KAXErrorInvalidUIElementObserver, REF, :pie, :cake],
#          should_raise: ArgumentError,
#        with_fragments: [/no longer a valid observer/, /or was never valid/, ref, /cake/]
#   end

#   def test_cannot_complete
#     def self.pid_for lol
#       NSRunningApplication
#         .runningApplicationsWithBundleIdentifier('com.apple.finder')
#         .first.processIdentifier
#     end
#     error_handler_test [KAXErrorCannotComplete, REF],
#          should_raise: RuntimeError,
#        with_fragments: [/An unspecified error/, ref, /:\(/]

#     def self.pid_for lol; false; end
#     error_handler_test [KAXErrorCannotComplete, nil],
#          should_raise: RuntimeError,
#        with_fragments: [/Application for pid/, /Maybe it crashed\?/]
#   end

#   def test_attr_unsupported
#     error_handler_test [KAXErrorAttributeUnsupported, REF, :cake],
#          should_raise: ArgumentError,
#        with_fragments: [/does not have/, /:cake attribute/, ref]
#   end

#   def test_action_unsupported
#     error_handler_test [KAXErrorActionUnsupported, REF, :pie],
#          should_raise: ArgumentError,
#        with_fragments: [/does not have/, /:pie action/, ref]
#   end

#   def test_notif_unsupported
#     error_handler_test [KAXErrorNotificationUnsupported, REF, :cheese],
#          should_raise: ArgumentError,
#        with_fragments: [/does not support/, /:cheese notification/, ref]
#   end

#   def test_not_implemented
#     error_handler_test [KAXErrorNotImplemented, REF],
#          should_raise: NotImplementedError,
#        with_fragments: [/does not work with AXAPI/, ref]
#   end

#   def test_notif_registered
#     error_handler_test [KAXErrorNotificationAlreadyRegistered, REF, :lamp],
#          should_raise: ArgumentError,
#        with_fragments: [/already registered/, /:lamp/, ref]
#   end

#   def test_notif_not_registered
#     error_handler_test [KAXErrorNotificationNotRegistered, REF, :peas],
#          should_raise: RuntimeError,
#        with_fragments: [/not registered/, /:peas/, ref]
#   end

#   def test_api_disabled
#     error_handler_test [KAXErrorAPIDisabled],
#          should_raise: RuntimeError,
#        with_fragments: [/AXAPI has been disabled/]
#   end

#   def test_param_attr_unsupported
#     error_handler_test [KAXErrorParameterizedAttributeUnsupported, REF, :oscar],
#          should_raise: ArgumentError,
#        with_fragments: [/does not have/, /:oscar parameterized attribute/, ref]
#   end

#   def test_not_enough_precision
#     error_handler_test [KAXErrorNotEnoughPrecision],
#          should_raise: RuntimeError,
#        with_fragments: [/not enough precision/, '¯\(°_o)/¯']
#   end

# end


# class TestCoreExtensionsForCore < MiniTest::Unit::TestCase
#   include Accessibility::Core

#   def test_to_axvalue_wraps_things
#     # point_makes_a_value
#     value = CGPointZero.to_axvalue
#     ptr   = Pointer.new CGPoint.type
#     AXValueGetValue(value, 1, ptr)
#     assert_equal CGPointZero, ptr[0]

#     # size_makes_a_value
#     value = CGSizeZero.to_axvalue
#     ptr   = Pointer.new CGSize.type
#     AXValueGetValue(value, 2, ptr)
#     assert_equal CGSizeZero, ptr[0]

#     # rect_makes_a_value
#     value = CGRectZero.to_axvalue
#     ptr   = Pointer.new CGRect.type
#     AXValueGetValue(value, 3, ptr)
#     assert_equal CGRectZero, ptr[0]

#     # range_makes_a_value
#     range = CFRange.new(5, 4)
#     value = range.to_axvalue
#     ptr   = Pointer.new CFRange.type
#     AXValueGetValue(value, 4, ptr)
#     assert_equal range, ptr[0]
#   end

#   def test_to_axvalue_on_non_boxes
#     obj = Object.new
#     assert_respond_to obj, :to_axvalue
#     assert_equal obj.self, obj.to_axvalue
#   end

#   def test_to_axvalue_raises_for_unsupported_boxes
#     assert_raises NotImplementedError do
#       NSEdgeInsets.new.to_axvalue
#     end
#   end

#   def test_to_axvalue_for_ranges
#     assert_equal CFRangeMake(1,10).to_axvalue, (1..10  ).to_axvalue
#     assert_equal CFRangeMake(1, 9).to_axvalue, (1...10 ).to_axvalue
#     assert_equal CFRangeMake(0, 3).to_axvalue, (0..2   ).to_axvalue
#   end

#   def test_to_axvalue_for_ranges_raises_for_bad_ranges
#     assert_raises ArgumentError do
#       (1..-10).to_axvalue
#     end
#     assert_raises ArgumentError do
#       (-5...10).to_axvalue
#     end
#   end

#   def test_to_value_on_boxes
#     assert_equal CGPointZero,       CGPointZero.to_axvalue.to_value
#     assert_equal CGSizeMake(10,10), CGSizeMake(10,10).to_axvalue.to_value
#     assert_equal Range.new(1,10),   CFRange.new(1,10).to_value
#   end

#   def test_to_value_on_non_boxes
#     obj = Object.new
#     assert_equal obj.self, obj.to_value
#   end

#   # trivial but important for backwards compat with Snow Leopard
#   def test_identifier_const
#     assert Object.const_defined? :KAXIdentifierAttribute
#     assert_equal 'AXIdentifier', KAXIdentifierAttribute
#   end

#   def test_to_range
#     assert_equal CFRange.new(10,11), [10,11].to_range
#     assert_equal [12,13], [12,13].to_range.to_a
#   end

#   def test_to_point
#     assert_equal CGPointZero, CGPointZero.to_point
#     assert_equal CGPointMake(2,3), CGPointMake(2,3).to_point

#     assert_instance_of CGPoint, [1, 1].to_point
#     assert_equal [2,3], [2,3].to_point.to_a
#     assert_equal CGPoint.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_point
#   end

#   def test_to_size
#     assert_instance_of CGSize, [1, 1].to_size
#     assert_equal [2,3], [2,3].to_size.to_a
#     assert_equal CGSize.new(1,2), NSArray.arrayWithArray([1, 2, 3]).to_size
#   end

#   def test_to_rect
#     assert_instance_of CGRect, [1, 1, 1, 1].to_rect
#     assert_equal [2,3,4,5], [2,3,4,5].to_rect.to_a.map(&:to_a).flatten
#     assert_equal CGRectMake(6,7,8,9), [6,7,8,9,10].to_rect
#   end

# end
end
