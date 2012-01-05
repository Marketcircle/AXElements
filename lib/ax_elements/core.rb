# -*- coding: utf-8 -*-

##
# Namespace for all the accessibility objects, as well as core
# abstraction layer that that interacts with OS X Accessibility
# APIs (AXAPI).
module AX
  @ignore_notifs = true
  @notifs        = {}
end

# Load the key_coder extension after {AX} has been defined.
require 'ax_elements/key_coder'

##
# @todo I feel a bit weird having to instantiate a new pointer every
#       time I want to fetch an attribute. Since allocations are costly,
#       it hurts performance a lot when it comes to searches. I wonder if
#       it would pay off to have a pool of pointers...
#
# The singleton methods for the AX module wrap all AXAPI methods that are
# used by AXElements. This forms the core layer of abstraction for
# AXElements.
#
# The methods provide a clean Ruby-ish interface to the low level
# CoreFoundation functions that compose AXAPI. In doing this, we can hide
# away the need to work with pointers and centralize how AXAPI related
# errors are handled (since CoreFoundation uses a different pattern for
# that sort of thing).
#
# Ideally this API would be stateless, but I'm still working on that...
class << AX


  # @group Attributes

  ##
  # @note Passing invalid values for the argument does not always raise
  #       an error. This is a "feature" of AXAPI that AXElements does not
  #       check for at the moment.
  #
  # Get the list of attributes for a given element.
  #
  # @example
  #
  #   AX.attrs_of_element(AXUIElementCreateSystemWide())
  #     # => ["AXRole", "AXRoleDescription", "AXFocusedUIElement", "AXFocusedApplication"]
  #
  # @param [AXUIElementRef]
  # @return [Array<String>]
  def attrs_of_element element
    ptr = Pointer.new ARRAY
    case AXUIElementCopyAttributeNames(element, ptr)
    when 0                        then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorIllegalArgument  then
      msg = "'#{CFCopyDescription(element)}' is not an AXUIElementRef"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(element)
    when KAXErrorFailure          then failure_message
    when KAXErrorCannotComplete   then cannot_complete_message
    when KAXErrorNotImplemented   then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # Get the size of the array for attributes that would return an array.
  # This is useful when you only want to know how large the array is and
  # performance matters.
  #
  # @example
  #
  #   AX.attr_count_of_element(window, KAXChildrenAttribute) # => 19
  #   AX.attr_conut_of_element(button, KAXChildrenAttribute) # => 0
  #
  # @param [AXUIElementRef]
  # @param [String] attr an attribute constant
  # @return [Fixnum]
  def attr_count_of_element element, attr
    ptr = Pointer.new :long_long
    case AXUIElementGetAttributeValueCount(element, attr, ptr)
    when 0                            then ptr[0] # KAXErrorSuccess
    when KAXErrorIllegalArgument      then
      msg  = "Either the element '#{CFCopyDescription(element)}' "
      msg << "or the attr '#{attr}' is not a legal argument"
      raise ArgumentError, msg
    when KAXErrorAttributeUnsupported then unsupported_message(element, attr)
    when KAXErrorInvalidUIElement     then invalid_element_message(element)
    when KAXErrorCannotComplete       then cannot_complete_message
    when KAXErrorNotImplemented       then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # Fetch the value for a given attribute of a given element. You will
  # be given raw data from this method; that is, `Boxed` objects will
  # still be wrapped in a `AXValueRef`, and elements will be
  # `AXUIElementRef` objects instead of wrapped {AX::Element} objects.
  #
  # @example
  #   AX.attr_of_element window, KAXTitleAttribute   # => "HotCocoa Demo"
  #   AX.attr_of_element window, KAXSizeAttribute    # => #<AXValueRefx00000000>
  #   AX.attr_of_element window, KAXParentAttribute  # => #<AXUIElementRefx00000000>
  #   AX.attr_of_element window, KAXNoValueAttribute # => nil
  #
  # @param [AXUIElementRef]
  # @param [String] attr an attribute constant
  def attr_of_element element, attr
    ptr = Pointer.new :id
    case AXUIElementCopyAttributeValue(element, attr, ptr)
    when 0                        then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorNoValue          then nil
    when KAXErrorIllegalArgument  then
      msg  = "The element '#{CFCopyDescription(element)}' "
      msg << "or the attr '#{attr}' is not a legal argument"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(element)
    when KAXErrorCannotComplete   then cannot_complete_message
    when KAXErrorNotImplemented   then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # @todo Determine if the performance gain is worth it.
  # @todo Should we handle cases where a subrole has a value of
  #       'Unknown'? What is the performance impact?
  #
  # @note You might get `nil` back as the subrole, so you need to check.
  #
  # Quick macro for getting the subrole/role pair for a given
  # element. This is equivalent to calling {AX.attr_of_element}
  # twice; once to get the role, and a second time to get the subrole.
  # The pair is ordered with the subrole first.
  #
  # @example
  #   AX.role_pair_for(window_ref)   # => ["AXDialog", "AXWindow" ]
  #   AX.role_pair_for(web_area_ref) # => [nil,        "AXWebArea"]
  #
  # @param [AXUIElementRef]
  # @return [Array(String,String), Array(nil,String)]
  def role_pair_for element
    role = role_for element
    ptr  = Pointer.new :id
    # @todo Handle error codes?
    AXUIElementCopyAttributeValue(element, SUBROLE, ptr)
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
  #   AX.role_for(window_ref) # => KAXWindowRole
  #   AX.role_for(button_ref) # => KAXButtonRole
  #
  # @param [AXUIElementRef]
  # @return [String]
  def role_for element
    ptr = Pointer.new :id
    AXUIElementCopyAttributeValue(element, ROLE, ptr)
    ptr[0]
  end

  ##
  # Returns whether or not an attribute is writable for a specific element.
  #
  # @example
  #   AX.attr_of_element_writable?(window_ref, KAXSizeAttribute)  # => true
  #   AX.attr_of_element_writable?(window_ref, KAXTitleAttribute) # => false
  #
  # @param [AXUIElementRef]
  # @param [String] attr an attribute constant
  def attr_of_element_writable? element, attr
    ptr = Pointer.new :bool
    case AXUIElementIsAttributeSettable(element, attr, ptr)
    when 0                            then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorNoValue              then false
    when KAXErrorCannotComplete       then cannot_complete_message
    when KAXErrorIllegalArgument      then
      msg  = "Either the element '#{CFCopyDescription(element)}' "
      msg << "or the attr '#{attr}' is not a legal argument"
      raise ArgumentError, msg
    when KAXErrorAttributeUnsupported then unsupported_message(element, attr)
    when KAXErrorInvalidUIElement     then invalid_element_message(element)
    when KAXErrorNotImplemented       then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # @note This method does not check writability of the attribute
  #       you are setting.
  #
  # Set the given value to the given attribute of the given element.
  #
  # @example
  #   AX.set_attr_of_element(slider,     KAXValueAttribute, 25)   # => 25
  #   AX.set_attr_of_element(text_field, KAXValueAttribute, 'hi') # => "hi"
  #
  # @param [AXUIElementRef]
  # @param [String] attr an attribute constant
  # @param [Object] value the new value to set on the attribute
  # @return [Object] returns the value that was set
  def set_attr_of_element element, attr, value
    case AXUIElementSetAttributeValue(element, attr, value)
    when 0                            then value # KAXErrorSuccess, perf hack
    when KAXErrorIllegalArgument      then
      msg  = "You can't set '#{attr}' to '#{CFCopyDescription(value)}' "
      msg << "for '#{CFCopyDescription(element)}'"
      raise ArgumentError, msg
    when KAXErrorAttributeUnsupported then unsupported_message(element, attr)
    when KAXErrorInvalidUIElement     then invalid_element_message(element)
    when KAXErrorCannotComplete       then cannot_complete_message
    when KAXErrorNotImplemented       then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end


  # @group Actions

  ##
  # Get the list of actions that the given element can perform. If an
  # element does not have actions, then an empty list will be returned.
  #
  # @example
  #
  #   AX.actions_of_element(button_ref) # => ["AXPress"]
  #   AX.actions_of_element(menu_ref)   # => ["AXOpen", "AXCancel"]
  #   AX.actions_of_element(window_ref) # => []
  #
  # @param [AXUIElementRef]
  # @return [Array<String>]
  def actions_of_element element
    ptr = Pointer.new ARRAY
    case AXUIElementCopyActionNames(element, ptr)
    when 0                        then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorIllegalArgument  then
      msg = "'#{CFCopyDescription(element)}' is not an AXUIElementRef"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(element)
    when KAXErrorFailure          then failure_message
    when KAXErrorCannotComplete   then cannot_complete_message
    when KAXErrorNotImplemented   then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # Tell an element to perform the given action. This method will always
  # return true or raise an exception. Actions should never fail.
  #
  # @example
  #
  #   AX.action_of_element(button_ref, KAXPressAction) # => true
  #   AX.action_of_element(menu_ref,   KAXOpenAction)  # => true
  #
  # @param [AXUIElementRef]
  # @param [String] action an action constant
  # @return [Boolean]
  def action_of_element element, action
    case AXUIElementPerformAction(element, action)
    when 0                         then true # KAXErrorSuccess, perf hack
    when KAXErrorActionUnsupported then unsupported_message(element, action)
    when KAXErrorIllegalArgument
      msg  = "The element '#{CFCopyDescription(element)}' "
      msg << "or the action '#{attr}' is not a legal argument"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement  then invalid_element_message(element)
    when KAXErrorCannotComplete    then cannot_complete_message
    when KAXErrorNotImplemented    then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # Generate keyboard events given a string of characters.
  #
  # In cases where you need (or want) to simulate keyboard input, such
  # as triggering hotkeys, you will need to use this method. There are
  # a lot of details on how to use this method, so the full
  # documentation is in the
  # {file:docs/KeyboardEvents.markdown Keyboard Events} tutorial.
  #
  # @example
  #
  #   AX.keyboard_action safari_ref, "www.macruby.org\r"
  #
  # @param [AXUIElementRef] element must be an application or
  #   the system-wide accessibility object
  # @param [String] string keyboard events as a string
  # @return [nil]
  def keyboard_action element, string
    post_kb_events element, parse_kb_string(string)
    nil
  end


  # @group Parameterized Attributes

  ##
  # List of parameterized attributes for the given element. If an
  # element does not have parameterized attributes, then an empty
  # list will be returned.
  #
  # Most elements do not have parameterized attributes, but the ones
  # that do, have many.
  #
  # @example
  #
  #   AX.param_attrs_of_element(text_field_ref) # => ["AXStringForRange", ...]
  #   AX.param_attrs_of_element(window_ref)     # => []
  #
  # @param [AXUIElementRef]
  # @return [Array<String>]
  def param_attrs_of_element element
    ptr = Pointer.new ARRAY
    case AXUIElementCopyParameterizedAttributeNames(element, ptr)
    when 0                        then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorAttributeUnsupported,
         KAXErrorParameterizedAttributeUnsupported then
      msg = "'#{CFCopyDescription(element)}' does not have parameterized attributes"
      raise ArgumentError, msg
    when KAXErrorIllegalArgument  then
      msg = "'#{CFCopyDescription(element)}' is not an AXUIElementRef"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(element)
    when KAXErrorFailure          then failure_message
    when KAXErrorCannotComplete   then cannot_complete_message
    when KAXErrorNotImplemented   then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
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
  #   range = CFRange.new(1, 10).to_axvalue
  #   AX.param_attr_of_element(text_field_ref, KAXStringForRangeParameterizedAttribute, range)
  #     # => "ello, worl"
  #
  # @param [AXUIElementRef]
  # @param [String] attr an attribute constant
  def param_attr_of_element element, attr, param
    ptr = Pointer.new :id
    case AXUIElementCopyParameterizedAttributeValue(element, attr, param, ptr)
    when 0               then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorNoValue then nil
    when KAXErrorAttributeUnsupported,
         KAXErrorParameterizedAttributeUnsupported then
      unsupported_message(element, attr)
    when KAXErrorIllegalArgument
      msg  = "You can't set '#{attr}' to '#{CFCopyDescription(param)}' "
      msg << "for '#{CFCopyDescription(element)}'"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(element)
    when KAXErrorCannotComplete   then cannot_complete_message
    when KAXErrorNotImplemented   then not_implemented_message(element)
    else
      raise 'You should never reach this line!'
    end
  end


  # @group Element Entry Points

  ##
  # Find the element at a point on the screen that belongs to a given
  # application.
  #
  # The coordinates should be specified using the flipped coordinate
  # system (origin is in the top-left, increasing downward as if reading
  # a book in English).
  #
  # If more than one element is at the position then the
  # z-order of the elements will be used to determine which is
  # "on top". To get the absolute top element, regardless of application,
  # then pass system-wide element for the `app`.
  #
  # @example
  #
  #   AX.element_at_point(safari_ref,      453, 200) # web area for active tab
  #   AX.element_at_point(system_wide_ref, 453, 200) # table from finder
  #
  # @param [AXUIElementRef]
  # @param [Float]
  # @param [Float]
  # @return [AXUIElementRef]
  def element_at_point app, x, y
    ptr = Pointer.new ELEMENT
    case AXUIElementCopyElementAtPosition(app, x, y, ptr)
    when 0                        then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorNoValue          then nil
    when KAXErrorIllegalArgument  then
      msg  = "The point [#{x}, #{y}] is not a valid point, or "
      msg << "'#{CFCopyDescription(app)}' is not an AXUIElementRef"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(app)
    when KAXErrorCannotComplete   then cannot_complete_message
    when KAXErrorNotImplemented   then not_implemented_message(app)
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # Get the application accessibility object/token for an application
  # given the process identifier (PID) for that application.
  #
  # @example
  #
  #   app = AX.application_for_pid(safari_pid) # => #<AXUIElementRefx00000000>
  #   CFShow(app)
  #
  # @param [Fixnum]
  # @return [AXUIElementRef]
  def application_for_pid pid
    if NSRunningApplication.runningApplicationWithProcessIdentifier pid
      AXUIElementCreateApplication(pid)
    else
      raise ArgumentError, 'pid must belong to a running application'
    end
  end


  # @group Misc.

  ##
  # Get the process identifier (PID) of the application that the given
  # element belongs to.
  #
  # @example
  #
  #   AX.pid_of_element(safari_ref)     # => 12345
  #   AX.pid_of_element(text_field_ref) # => 12345
  #
  # @param [AXUIElementRef]
  # @return [Fixnum]
  def pid_of_element element
    ptr = Pointer.new :int
    case AXUIElementGetPid(element, ptr)
    when 0                        then ptr[0] # KAXErrorSuccess, perf hack
    when KAXErrorIllegalArgument  then
      msg = "'#{CFCopyDescription(element)}' is not a AXUIElementRef"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement then invalid_element_message(element)
    else
      raise 'You should never reach this line!'
    end
  end


  # @group Notifications

  ##
  # @todo This method is too big, needs refactoring. It's own class?
  #
  # {file:docs/Notifications.markdown Notifications} are a way to put
  # non-polling delays into your scripts.
  #
  # Use this method to register to be notified of the specified event in
  # an application. You must also pass a block to this method to validate
  # the notification.
  #
  # @param [AXUIElementRef] ref the element which will send the notification
  # @param [String] name the name of the notification
  # @yield Validate the notification; the block should return truthy if
  #        the notification received is the expected one and the script can stop
  #        waiting, otherwise should return falsy.
  # @yieldparam [AXUIElementRef] element the element that sent the notification
  # @yieldparam [String] notif the name of the notification
  # @yieldreturn [Boolean] determines if the script should continue or wait
  # @return [Array(Observer, AXUIElementRef, String)] the registration triple
  def register_for_notif ref, name, &block
    run_loop = CFRunLoopGetCurrent()

    # we are ignoring the context pointer since this is OO
    callback = Proc.new do |observer, element, notif, _|
      LOCK.synchronize do
        # puts "Received notif (#{notif}) for (#{element})"
        break if     @ignore_notifs
        break unless block.call(element, notif)

        @ignore_notifs = true
        source = AXObserverGetRunLoopSource(observer)
        CFRunLoopRemoveSource(run_loop, source, KCFRunLoopDefaultMode)
        unregister_notif_callback observer, element, notif
        CFRunLoopStop(run_loop)
      end
    end

    dude   = make_observer_for ref, callback
    source = AXObserverGetRunLoopSource(dude)
    register_notif_callback dude, ref, name
    CFRunLoopAddSource(run_loop, source, KCFRunLoopDefaultMode)
    @ignore_notifs = false

    # must keep [element, observer, notif] in order to do unregistration
    @notifs[dude] = [ref, name]
    [dude, ref, name]
  end

  ##
  # @todo Is it safe to end the run loop when _any_ source is handled or
  #       should we continue to kill the run loop when the callback is
  #       received?
  #
  # Pause execution of the program until a notification is received or a
  # timeout occurs.
  #
  # @param [Float] timeout
  # @return [Boolean] true if the notification was received, otherwise false
  def wait_for_notif timeout
    # We use RunInMode because it has timeout functionality, return values are
    case CFRunLoopRunInMode(KCFRunLoopDefaultMode, timeout, false)
    when KCFRunLoopRunStopped  # Stopped with CFRunLoopStop.
      true
    when KCFRunLoopRunTimedOut # Time interval seconds passed.
      false
    when KCFRunLoopFinished    # Mode has no sources or timers.
      raise 'Something went wrong with setting up the run loop'
    when KCFRunLoopRunHandledSource
      # Only applies when returnAfterSourceHandled is true.
      raise 'This should never happen'
    else
      raise 'You just found a an OS X bug (or a MacRuby bug)...'
    end
  end

  ##
  # @todo Flush any waiting notifs?
  #
  # Cancel _all_ notification registrations. Simple and clean, but a
  # blunt tool at best. I didn't have time to figure out a better
  # system :(
  #
  # @return [nil]
  def unregister_notifs
    LOCK.synchronize do
      @ignore_notifs = true
      @notifs.each_pair do |observer, pair|
        unregister_notif_callback observer, *pair
      end
      @notifs = {}
    end
  end

  # @endgroup


  private

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
  # @private
  #
  # Local copy of a Cocoa constant; this is a performance hack.
  #
  # @return [String]
  ROLE     = KAXRoleAttribute

  ##
  # @private
  #
  # Local copy of a Cocoa constant; this is a performance hack.
  #
  # @return [String]
  SUBROLE  = KAXSubroleAttribute

  # @group Notifications

  ##
  # @todo Would a Dispatch::Semaphore be better?
  #
  # Semaphore used to synchronize async notification stuff.
  #
  # @return [Mutex]
  LOCK     = Mutex.new

  # @endgroup

  ##
  # Map of characters to keycodes. The map is generated at boot time in
  # order to support multiple keyboard layouts.
  #
  # @return [Hash]
  KEYCODE_MAP = {}


  ##
  # Parse a string into a list of keyboard events to be executed in
  # the given order.
  #
  # @param [String]
  # @return [Array<Array(Number,Boolean)>]
  def parse_kb_string string
    sequence = []
    string.each_char do |char|
      if char.match(/[A-Z]/)
        code  = AX::KEYCODE_MAP[char.downcase]
        event = [[56,true], [code,true], [code,false], [56,false]]
      else
        code  = AX::KEYCODE_MAP[char]
        event = [[code,true],[code,false]]
      end
      sequence.concat event
    end
    sequence
  end

  ##
  # Post the list of given keyboard events to the given application,
  # or the system-wide accessibility object.
  #
  # This is a private API, and the events passed should always be
  # generated by {AX.parse_kb_string}.
  #
  # @param [AXUIElementRef]
  # @param [Array<Array(Number,Boolean)>]
  def post_kb_events element, events
    # This is just a magic number from trial and error. I tried both the repeat interval (NXKeyRepeatInterval) and threshold (NXKeyRepeatThreshold) but both were way too big.
    key_rate = 0.009

    events.each do |event|
      case AXUIElementPostKeyboardEvent(element, 0, *event)
      when 0 # KAXErrorSuccess, perf hack
      when KAXErrorIllegalArgument  then
        msg  = "'#{CFCopyDescription(element)}' or #{event.inspect} "
        msg << 'is not a legal argument'
        raise ArgumentError, msg
      when KAXErrorInvalidUIElement then invalid_element_message(element)
      when KAXErrorFailure          then failure_message
      when KAXErrorCannotComplete   then cannot_complete_message
      when KAXErrorNotImplemented   then not_implemented_message(element)
      else
        raise 'You should never reach this line!'
      end
    end

    sleep events.count * key_rate
  end

  def unsupported_message element, attr
    msg = "'#{CFCopyDescription(element)}' doesn't have '#{attr}'"
    raise ArgumentError, msg
  end

  def invalid_element_message element
    msg = "'#{CFCopyDescription(element)}' is no longer a valid token"
    raise RuntimeError, msg
  end

  def cannot_complete_message
    raise RuntimeError, 'Some unspecified error occurred with AXAPI. Sorry. :('
  end

  def failure_message
    raise RuntimeError, 'Some kind of system failure occurred, stopping to be safe'
  end

  def not_implemented_message element
    msg  = "The program that owns '#{CFCopyDescription(element)}' "
    msg << 'does not work with AXAPI properly'
    raise NotImplementedError, msg
  end

  ##
  # Create and return a notification observer for the given object's
  # application.
  #
  # @param [AXUIElementRef] element
  # @param [Method,Proc] callback
  # @return [AXObserverRef]
  def make_observer_for element, callback
    ptr  = Pointer.new OBSERVER
    case AXObserverCreate(pid_of_element(element), callback, ptr)
    when KAXErrorSuccess
      ptr[0]
    when KAXErrorIllegalArgument
      show2 element, callback,
        "Either '#{element}' or '#{callback.inspect}' is not a valid argument"
    when KAXErrorFailure
      raise 'Some kind of system failure occurred, stopping to be safe'
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # @todo Consider exposing the refcon argument. Probably not until
  #       someone actually wants to pass a context around.
  #
  # Register an observer for a specific event.
  #
  # @param [AXObserverRef]
  # @param [AX::Element]
  # @param [String]
  def register_notif_callback observer, element, notif
    case AXObserverAddNotification(observer, element, notif, nil)
    when KAXErrorSuccess
    when KAXErrorInvalidUIElementObserver
      show observer, "'#{observer}' is no longer valid or was never valid"
    when KAXErrorIllegalArgument
      show3 observer, element, notif
        "Either '#{observer}', '#{element}', or '#{notif}' is not valid"
    when KAXErrorNotificationUnsupported
      show element, "Apparently '#{element}' does not support notifications"
    when KAXErrorNotificationAlreadyRegistered
      CFShow(element)
      warn "You have already registered to hear about '#{notif}' from '#{element}'"
    when KAXErrorCannotComplete
      raise 'Some unspecified problem occurred with the AXAPI. Sorry. :('
    when KAXErrorFailure
      raise 'Some kind of system failure occurred, stopping to be safe'
    else
      raise 'You should never reach this line'
    end
  end

  ##
  # Unregister a notification that has been previously setup.
  #
  # @param [AXObserverRef]
  # @param [AX::Element]
  # @param [String]
  def unregister_notif_callback observer, ref, notif
    case AXObserverRemoveNotification(observer, ref, notif)
    when KAXErrorSuccess
    when KAXErrorNotificationNotRegistered
      Accessibility.log.warn  "Notif no longer registered: (#{ref}:#{notif})"
    when KAXErrorIllegalArgument
      raise ArgumentError,    "Notif not unregistered (#{ref}:#{notif})"
    when KAXErrorInvalidUIElementObserver
      show observer, "'#{observer}' is no longer valid or was never valid"
    when KAXErrorIllegalArgument
      show3 observer, element, notif
        "Either '#{observer}', '#{element}', or '#{notif}' is not valid"
    when KAXErrorNotificationUnsupported
      show element, "Apparently '#{element}' does not support notifications"
    when KAXErrorNotificationNotRegistered
      CFShow(element)
      raise "You have not yet registered to heard about '#{notif}' from '#{element}'"
    when KAXErrorCannotComplete
      raise 'Some unspecified problem occurred with the AXAPI. Sorry. :('
    when KAXErrorFailure
      raise 'Some kind of system failure occurred, stopping to be safe'
    else
      raise 'You should never reach this line!'
    end
  end

end
