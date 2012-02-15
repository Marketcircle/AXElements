# -*- coding: utf-8 -*-

##
# @todo I feel a bit weird having to instantiate a new pointer every
#       time I want to fetch an attribute. Since allocations are costly,
#       it hurts performance a lot when it comes to searches. I wonder if
#       it would pay off to have a pool of pointers...
#
# Core abstraction layer that that interacts with OS X Accessibility
# APIs (AXAPI). You can just mix this module in wherever you want to add
# some accessibility calls.
#
# All AXAPI methods that are used should be first wrapped in this module.
# This module is responsible for handling pointers and dealing with error
# codes for functions that make use of them.
#
# The methods in this module provide a clean Ruby-ish interface to the low
# level CoreFoundation functions that compose AXAPI. In doing this, we can
# hide away the need to work with pointers and centralize how AXAPI related
# errors are handled (since CoreFoundation uses a different pattern for
# that sort of thing).
#
# This module is stateless and should therefore be threadsafe.
module Accessibility::Core


  private

  # @group Attributes

  ##
  # @note Invalid values for the argument do not always raise an error.
  #       This is a "feature" of AXAPI thas is not checked for by AXElements.
  #
  # Get the list of attributes for a given element.
  #
  # @example
  #
  #   attrs_for AXUIElementCreateSystemWide()
  #     # => ["AXRole", "AXRoleDescription",
  #     #     "AXFocusedUIElement", "AXFocusedApplication"]
  #
  # @param [AXUIElementRef]
  # @return [Array<String>]
  def attrs_for element
    ptr  = Pointer.new ARRAY
    code = AXUIElementCopyAttributeNames(element, ptr)
    return ptr[0] if code.zero?
    handle_error code, element
  end

  ##
  # Get the size of the array for attributes that would return an array.
  # When performance matters, this is much faster than getting the array
  # and asking for the size; at least until memory allocations are not so
  # slow in MacRuby.
  #
  # @example
  #
  #   size_of KAXChildrenAttribute, for: window  # => 19
  #   size_of KAXChildrenAttribute, for: button  # => 0
  #
  # @param [String] attr an attribute constant
  # @param [AXUIElementRef]
  # @return [Fixnum]
  def size_of attr, for: element
    ptr  = Pointer.new :long_long
    code = AXUIElementGetAttributeValueCount(element, attr, ptr)
    return ptr[0] if code.zero?
    handle_error code, element, attr
  end

  ##
  # Fetch the value for a given attribute of a given element. You will
  # be given raw data from this method; that is, `Boxed` objects will
  # still be wrapped in a `AXValueRef`, and elements will be
  # `AXUIElementRef` objects instead of wrapped {AX::Element} objects.
  #
  # @example
  #   attr KAXTitleAttribute,   for: window  # => "HotCocoa Demo"
  #   attr KAXSizeAttribute,    for: window  # => #<AXValueRef>
  #   attr KAXParentAttribute,  for: window  # => #<AXUIElementRef>
  #   attr KAXNoValueAttribute, for: window  # => nil
  #
  # @param [String] attr an attribute constant
  # @param [AXUIElementRef]
  def attr attr, for: element
    ptr  = Pointer.new :id
    code = AXUIElementCopyAttributeValue(element, attr, ptr)
    return ptr[0] if code.zero?
    return nil    if code == KAXErrorNoValue
    handle_error code, element, attr
  end

  ##
  # @note This method becomes faster than calling {attr:for:} at ~3
  #       attributes; complexity of this method is sublinear for
  #       increasing sizes of `attrs`.
  #
  # Fetch multiple attribute values for the given element at once. You will
  # be given raw data from this method; that is, `Boxed` objects will
  # still be wrapped in a `AXValueRef`, and elements will be
  # `AXUIElementRef` objects instead of wrapped {AX::Element} objects.
  #
  # @example
  #   attrs [KAXPositionAttribute, KAXSizeAttribute], for: window
  #       # => [#<AXValueRefx00000000>, #<AXValueRefx00000000>]
  #
  #   attrs [KAXParentAttribute],  for: window  # => [#<AXUIElementRef>]
  #   attrs [KAXNoValueAttribute], for: window  # => [nil]
  #
  # @param [Array<String>]
  # @param [AXUIElementRef]
  # @return [Array]
  def attrs attrs, for: element
    ptr  = Pointer.new ARRAY
    code = AXUIElementCopyMultipleAttributeValues(element, attrs, 0, ptr)
    return ptr[0].map { |x|
      AXValueGetType(x) == KAXValueAXErrorType ? nil : x
    } if code.zero? || code == KAXErrorNoValue
    handle_error code, element, attrs
  end

  ##
  # @note Error codes are not checked here, you should only call this
  #       method if you know the element has a subrole.
  # @note You might get `nil` back as the subrole, so you need to check.
  #
  # Quick macro for getting the subrole/role pair for a given
  # element. This is equivalent to calling `AX.attr:for:`
  # twice; once to get the role, and a second time to get the subrole.
  # The pair is ordered with the subrole first.
  #
  # @example
  #   role_pair_for window_ref    # => ["AXDialog", "AXWindow" ]
  #   role_pair_for web_area_ref  # => [nil,        "AXWebArea"]
  #
  # @param [AXUIElementRef]
  # @return [Array(String,String), Array(nil,String)]
  def role_pair_for element
    role = role_for element
    ptr  = Pointer.new :id
    AXUIElementCopyAttributeValue(element, KAXSubroleAttribute, ptr)
    [ptr[0], role]
  end

  ##
  # @todo Determine if the performance gain is worth it.
  #
  # @note Currently making an assumption about roles always being valid
  #       since it is the one requirement of all accessibility objects.
  #
  # Quick macro for getting the `KAXRoleAttribute` value for a given
  # element. This is equivalent to calling
  # `AX.attr_of_element(element, KAXRoleAttribute)` except that it
  # should be slightly faster.
  #
  # @example
  #
  #   role_for window_ref  # => KAXWindowRole
  #   role_for button_ref  # => KAXButtonRole
  #
  # @param [AXUIElementRef]
  # @return [String]
  def role_for element
    ptr = Pointer.new :id
    AXUIElementCopyAttributeValue(element, KAXRoleAttribute, ptr)
    ptr[0]
  end

  ##
  # Equivalent to calling {attr:for:} with the first argument being
  # `KAXChildrenAttribute` and the second argument being what you
  # passed to this method.
  #
  # @example
  #
  #   children_for application_ref # => [MenuBar, Window, ...]
  #
  # @param [AXUIElementRef]
  # @return [Array<AX::Element>]
  def children_for element
    attr KAXChildrenAttribute, for: element
  end

  ##
  # Equivalent to calling {attr:for:} with the first argument being
  # `KAXValueAttribute` and the second argument being what you
  # passed to this method.
  #
  # @example
  #
  #   value_for text_field_ref # => "Mark Rada"
  #   value_for slider_ref     # => 42
  #
  # @param [AXUIElementRef]
  # @return [Array<AX::Element>]
  def value_for element
    attr KAXValueAttribute, for: element
  end

  ##
  # Returns whether or not an attribute is writable for a specific element.
  #
  # @example
  #   writable_attr? KAXSizeAttribute,  for: window_ref  # => true
  #   writable_attr? KAXTitleAttribute, for: window_ref  # => false
  #
  # @param [String] attr an attribute constant
  # @param [AXUIElementRef]
  def writable_attr? attr, for: element
    ptr  = Pointer.new :bool
    code = AXUIElementIsAttributeSettable(element, attr, ptr)
    return ptr[0] if code.zero?
    return false  if code == KAXErrorNoValue
    handle_error code, element, attr
  end

  ##
  # @note This method does not check writability of the attribute
  #       you are setting.
  #
  # Set the given value to the given attribute of the given element.
  #
  # @example
  #   set KAXValueAttribute, to: 25,   for: slider      # => 25
  #   set KAXValueAttribute, to: "hi", for: text_field  # => "hi"
  #
  # @param [String] attr an attribute constant
  # @param [Object] value the new value to set on the attribute
  # @param [AXUIElementRef]
  # @return [Object] returns the value that was set
  def set attr, to: value, for: element
    code = AXUIElementSetAttributeValue(element, attr, value)
    return value if code.zero?
    handle_error code, element, attr
  end


  # @group Actions

  ##
  # Get the list of actions that the given element can perform. If an
  # element does not have actions, then an empty list will be returned.
  #
  # @example
  #
  #   actions_for button_ref  # => ["AXPress"]
  #   actions_for menu_ref    # => ["AXOpen", "AXCancel"]
  #   actions_for window_ref  # => []
  #
  # @param [AXUIElementRef]
  # @return [Array<String>]
  def actions_for element
    ptr  = Pointer.new ARRAY
    code = AXUIElementCopyActionNames(element, ptr)
    return ptr[0] if code.zero?
    handle_error code, element
  end

  ##
  # Tell an element to perform the given action. This method will always
  # return true or raise an exception. Actions should never fail.
  #
  # @example
  #
  #   perform KAXPressAction, for: button_ref  # => true
  #   perform KAXOpenAction,  for: menu_ref    # => true
  #
  # @param [String] action an action constant
  # @param [AXUIElementRef]
  # @return [Boolean]
  def perform action, for: element
    code = AXUIElementPerformAction(element, action)
    return true if code.zero?
    handle_error code, element, action
  end

  ##
  # Post the list of given keyboard events to the given application,
  # or the system-wide accessibility object.
  #
  # Events could be generated from a string using output from
  # {Accessibility::StringParser}.
  #
  # Events are number/boolean tuples, where the number is a keycode
  # and the boolean is the keypress state (true is keydown, false is
  # keyup).
  #
  # You can learn more about keyboard events from the
  # {file:docs/KeyboardEvents.markdown Keyboard Events} documentation.
  #
  # @example
  #
  #   include Accessibility::StringParser
  #   events = create_events_for "Hello, world!\n"
  #   post events, to: safari_ref
  #
  # @param [Array<Array(Number,Boolean)>]
  # @param [AXUIElementRef]
  def post events, to: app
    events.each do |event|
      code = AXUIElementPostKeyboardEvent(app, 0, *event)
      handle_error code, app unless code.zero?
      sleep KEY_RATE
    end
  end


  # @group Parameterized Attributes

  ##
  # Get the list of parameterized attributes for the given element. If an
  # element does not have parameterized attributes, then an empty
  # list will be returned.
  #
  # Most elements do not have parameterized attributes, but the ones
  # that do, have many.
  #
  # @example
  #
  #   param_attrs_for text_field_ref  # => ["AXStringForRange", ...]
  #   param_attrs_for window_ref      # => []
  #
  # @param [AXUIElementRef]
  # @return [Array<String>]
  def param_attrs_for element
    ptr  = Pointer.new ARRAY
    code = AXUIElementCopyParameterizedAttributeNames(element, ptr)
    return ptr[0] if code.zero?
    handle_error code, element
  end

  ##
  # Fetch the given pramaeterized attribute value of a given a given element
  # using the given parameter. You will be given raw data from this method;
  # that is, `Boxed` objects will still be wrapped in a `AXValueRef`, and
  # elements will be `AXUIElementRef` objects instead of wrapped
  # {AX::Element} objects.
  #
  # If the parameter needs to be a range or some other C struct, then you
  # will need to wrap it in an `AXValueRef` before passing it to this
  # method.
  #
  # @example
  #
  #   r = CFRange.new(1, 10).to_axvalue
  #   param_attr KAXStringForRangeParameterizedAttribute, for_param: r, for: tf
  #     # => "ello, worl"
  #
  # @param [String] attr an attribute constant
  # @param [Object] param
  # @param [AXUIElementRef]
  def param_attr attr, for_param: param, for: element
    ptr  = Pointer.new :id
    code = AXUIElementCopyParameterizedAttributeValue(element,attr,param,ptr)
    return ptr[0] if code.zero?
    return nil    if code == KAXErrorNoValue
    handle_error code, element, attr, param
  end


  # @group Element Hierarchy Entry Points

  ##
  # Find the top most element at a point on the screen that belongs to
  # a given application.
  #
  # The coordinates should be specified using the flipped coordinate
  # system (origin is in the top-left, increasing downward and to the right
  # as if reading a book in English).
  #
  # If more than one element is at the position then the
  # z-order of the elements will be used to determine which is
  # "on top". To get the absolute top element, regardless of application,
  # then pass system-wide element for the `app`.
  #
  # @example
  #
  #   element_at_point 453, 200, for: safari_ref       # web area
  #   element_at_point 453, 200, for: system_wide_ref  # table
  #
  # @param [Float]
  # @param [Float]
  # @param [AXUIElementRef]
  # @return [AXUIElementRef]
  def element_at_point x, and: y, for: app
    ptr  = Pointer.new ELEMENT
    code = AXUIElementCopyElementAtPosition(app, x, y, ptr)
    return ptr[0] if code.zero?
    return nil    if code == KAXErrorNoValue
    handle_error code, app, x, y, nil
  end

  ##
  # Get the application accessibility object/token for an application
  # given the process identifier (PID) for that application.
  #
  # @example
  #
  #   app = application_for 54743  # => #<AXUIElementRefx00000000>
  #   CFShow(app)
  #
  # @param [Fixnum]
  # @return [AXUIElementRef]
  def application_for pid
    spin_run_loop
    if NSRunningApplication.runningApplicationWithProcessIdentifier pid
      AXUIElementCreateApplication(pid)
    else
      raise ArgumentError, 'pid must belong to a running application'
    end
  end


  # @group Notifications

  ##
  # Create and return a notification observer for the given object's
  # application. You can either pass a method reference, proc, or just
  # attach a regular block to this method, but you must choose one.
  #
  # Observer's belong to an application, so you can cache a particular
  # observer and use it for many different notification registrations.
  #
  # @example
  #
  #   observer_for pid_for(window_ref), calling: self.method(:notif_callback)
  #   observer_for pid_for(window_ref), calling: nil do
  #     |observer, element, notif, context|
  #     # do stuff...
  #   end
  #
  # @param [Number] pid
  # @param [Method,Proc,nil]
  # @yieldparam [AXObserverRef]
  # @yieldparam [AXUIElementRef]
  # @yieldparam [String]
  # @yieldparam [Object]
  # @return [AXObserverRef]
  def observer_for pid, calling: callback
    ptr  = Pointer.new OBSERVER
    code = AXObserverCreate(pid, (callback || Proc.new), ptr)
    return ptr[0] if code.zero?
    handle_error code, element, callback
  end

  ##
  # Get the run loop source for the given observer. You will need to
  # get the source for an observer added the a run loop source in
  # your script in order to begin receiving notifications.
  #
  # @example
  #
  #   # get the source
  #   source = run_loop_source_for observer
  #
  #   # add the source to the current run loop
  #   CFRunLoopAddSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
  #
  #   # don't forget to remove the source when you are done!
  #
  # @param [AXObserverRef]
  # @return [CFRunLoopSourceRef]
  def run_loop_source_for observer
    AXObserverGetRunLoopSource(observer)
  end

  ##
  # @todo Should passing around a context be supported?
  #
  # Register a notification observer for a specific event.
  #
  # @example
  #
  #   register observer, to_receive: KAXWindowCreatedNotification, from: window
  #
  # @param [AXObserverRef]
  # @param [String]
  # @param [AX::Element]
  # @return [Boolean]
  def register observer, to_receive: notif, from: element
    code = AXObserverAddNotification(observer, element, notif, nil)
    return true if code.zero?
    handle_error code, element, notif, observer, nil, nil
  end

  ##
  # Unregister a notification that has been previously setup.
  #
  # @param [AXObserverRef]
  # @param [String]
  # @param [AX::Element]
  # @return [Boolean]
  def unregister observer, from_receiving: notif, from: element
    code = AXObserverRemoveNotification(observer, element, notif)
    return true if code.zero?
    handle_error code, element, notif, observer, nil, nil
  end


  # @group Misc.

  ##
  # Ask whether or not AXAPI is enabled.
  #
  # @example
  #
  #   enabled?  # => true
  #
  #   # After unchecking "Enable access for assistive devices" in System Prefs
  #   enabled?  # => false
  #
  def enabled?
    AXAPIEnabled()
  end

  ##
  # Get the process identifier (PID) of the application that the given
  # element belongs to.
  #
  # @example
  #
  #   pid_for safari_ref      # => 12345
  #   pid_for text_field_ref  # => 12345
  #
  # @param [AXUIElementRef]
  # @return [Fixnum]
  def pid_for element
    ptr  = Pointer.new :int
    code = AXUIElementGetPid(element, ptr)
    return ptr[0] if code.zero?
    handle_error code, element
  end

  ##
  # Extract the stuct contained in an `AXValueRef`.
  #
  # @example
  #
  #   unwrap wrapped_point # => #<CGPoint x=44.3 y=99.0>
  #   unwrap wrapped_range # => #<CFRange begin=7 length=100>
  #
  # @param [AXValueRef]
  # @param [Number]
  # @return [Boxed]
  def unwrap value
    box_type = AXValueGetType(value)
    ptr      = Pointer.new BOX_TYPES[box_type]
    if AXValueGetValue(value, box_type, ptr)
      ptr[0]
    else
      raise ArgumentError, "'#{box_type.inspect}' is not a valid box type"
    end
  end

  ##
  # Wrap a `Boxed` object as an `AXValueRef`.
  #
  # @example
  #
  #   wrap CGPointMake(12, 34) # => #<AXValueRef:0x455678e2>
  #   wrap CGSizeMake(56, 78)  # => #<AXValueRef:0x555678e2>
  #
  # @param [Boxed]
  # @param [Class]
  # @return [AXValueRef]
  def wrap value
    klass = value.class
    ptr   = Pointer.new klass.type
    ptr.assign value
    AXValueCreate(klass.ax_value, ptr)
  end

  ##
  # Spin the run loop once. For the purpose of receiving notification
  # callbacks.
  #
  # @example
  #
  #   spin_run_loop # not much to it
  #
  # @return [self] returns the receiver
  def spin_run_loop
    NSRunLoop.currentRunLoop.runUntilDate Time.now
  end


  # @group Debug

  ##
  # Change the timeout value for an element or globally.
  #
  # To change the global value, pass the system wide object for
  # the `element` argument.
  #
  # @param [Number]
  # @param [AXUIElementRef]
  # @return [Number]
  def set_timeout_to seconds, for: element
    code = AXUIElementSetMessagingTimeout(element, seconds)
    return seconds if code.zero?
    handle_error code, element, seconds
  end


  # @group Error Handling

  # @param [Number]
  def handle_error code, *args
    args[0]              = args[0].description if args[0]
    klass, handler, argc = AXERROR[code] || [RuntimeError]
    msg                  = if handler
                             self.send handler, *args[argc]
                           else
                             "You should never reach this line [#{code}]"
                           end
    raise klass, msg, caller(1)
  end

  # @private
  def handle_failure ref
    "A system failure occurred with #{ref}, stopping to be safe"
  end

  # @private
  def handle_illegal_argument *args
    case args.size
    when 1
      "#{args.first} is not an AXUIElementRef"
    when 2
      "Either the element #{args.first} " +
        "or the attr/action/callback #{args.second.inspect} " +
        'is not a legal argument'
    when 3
      "You can't set #{args.second.inspect} to " +
        "#{args.third.description.inspect} for #{args.first}"
    when 4
      "The point [#{args.second}, #{args.third}] is not a valid point, " +
        "or #{args.first} is not an AXUIElementRef"
    when 5
      "Either the observer #{args.third.description}, " +
        "the element #{args.first}, or " +
        "the notification #{args.second.inspect} " +
        "is not a legitimate argument"
    end
  end

  # @private
  def handle_invalid_element ref
    "#{ref} is no longer a valid reference"
  end

  # @private
  def handle_invalid_observer ref, lol, obsrvr
    "#{obsrvr.description} is no longer a valid observer for #{ref}" +
      'or was never valid'
  end

  # @private
  # @param [AXUIElementRef]
  def handle_cannot_complete ref
    spin_run_loop
    pid = pid_for ref
    app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    if app
      "An unspecified error occurred using #{ref} with AXAPI, maybe a timeout"
    else
      "Application for pid=#{pid} is no longer running. Maybe it crashed?"
    end
  end

  # @private
  def handle_attr_unsupported ref, attr
    "#{ref} does not have a #{attr.inspect} attribute"
  end

  # @private
  def handle_action_unsupported ref, action
    "#{ref} does not have a #{action.inspect} action"
  end

  # @private
  def handle_notif_unsupported ref, notif
    "#{ref} does not support the #{notif.inspect} notification"
  end

  # @private
  def handle_not_implemented ref
    "The program that owns #{ref} does not work with AXAPI properly"
  end

  ##
  # @private
  # @todo Does this really neeed to raise an exception? Seems
  #       like a warning would be sufficient.
  def handle_notif_registered ref, notif
    "You have already registered to hear about #{notif.inspect} from #{ref}"
  end

  # @private
  def handle_notif_not_registered ref, notif
    "You have not registered to hear about #{notif.inspect} from #{ref}"
  end

  # @private
  def handle_api_disabled
    'AXAPI has been disabled'
  end

  # @private
  def handle_param_attr_unsupported ref, attr
    "#{ref} does not have a #{attr.inspect} parameterized attribute"
  end

  # @private
  def handle_not_enough_precision
    'AXAPI said there was not enough precision ¯\(°_o)/¯'
  end

  # @endgroup


  ##
  # Map of type encodings used for wrapping structs when coming from
  # an `AXValueRef`.
  #
  # The list is order sensitive, which is why we unshift nil, but
  # should probably be more rigorously defined at runtime.
  #
  # @return [String,nil]
  BOX_TYPES = [CGPoint, CGSize, CGRect, CFRange].map!(&:type).unshift(nil)

  ##
  # @private
  #
  # `Pointer` type encoding for `CFArrayRef` objects.
  #
  # @return [String]
  ARRAY    = '^{__CFArray}'.freeze

  ##
  # @private
  #
  # `Pointer` type encoding for `AXUIElementRef` objects.
  #
  # @return [String]
  ELEMENT  = '^{__AXUIElement}'.freeze

  ##
  # @private
  #
  # `Pointer` type encoding for `AXObserverRef` objects.
  #
  # @return [String]
  OBSERVER = '^{__AXObserver}'.freeze

  ##
  # The delay between key presses. The default value is `0.01`, which
  # should be about 50 characters per second (down and up are separate
  # events).
  #
  # This is just a magic number from trial and error. Both the repeat
  # interval (NXKeyRepeatInterval) and threshold (NXKeyRepeatThreshold),
  # but both were way too big.
  #
  # @return [Number]
  KEY_RATE = case ENV['KEY_RATE']
             when 'VERY_SLOW' then 1.0
             when 'SLOW'      then 0.1
             when nil         then 0.01
             else                  ENV['KEY_RATE'].to_f
             end

  ##
  # @private
  #
  # Mapping of `AXError` values to static information on how to handle
  # the error. Used by {handle_error}.
  #
  # @return [Hash{Number=>Array(Symbol,Range)}]
  AXERROR = {
    KAXErrorFailure                           =>
      [RuntimeError,        :handle_failure,                0...1],
    KAXErrorIllegalArgument                   =>
      [ArgumentError,       :handle_illegal_argument,       0..-1],
    KAXErrorInvalidUIElement                  =>
      [ArgumentError,       :handle_invalid_element,        0...1],
    KAXErrorInvalidUIElementObserver          =>
      [ArgumentError,       :handle_invalid_observer,       0...3],
    KAXErrorCannotComplete                    =>
      [RuntimeError,        :handle_cannot_complete,        0...1],
    KAXErrorAttributeUnsupported              =>
      [ArgumentError,       :handle_attr_unsupported,       0...2],
    KAXErrorActionUnsupported                 =>
      [ArgumentError,       :handle_action_unsupported,     0...2],
    KAXErrorNotificationUnsupported           =>
      [ArgumentError,       :handle_notif_unsupported,      0...2],
    KAXErrorNotImplemented                    =>
      [NotImplementedError, :handle_not_implemented,        0...1],
    KAXErrorNotificationAlreadyRegistered     =>
      [ArgumentError,       :handle_notif_registered,       0...2],
    KAXErrorNotificationNotRegistered         =>
      [RuntimeError,        :handle_notif_not_registered,   0...2],
    KAXErrorAPIDisabled                       =>
      [RuntimeError,        :handle_api_disabled,           0...0],
    KAXErrorParameterizedAttributeUnsupported =>
      [ArgumentError,       :handle_param_attr_unsupported, 0...2],
    KAXErrorNotEnoughPrecision                =>
      [RuntimeError,        :handle_not_enough_precision,   0...0]
  }

end
