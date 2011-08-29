require 'logger'

module Accessibility
  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log       = Logger.new $stderr
  @log.level = Logger::ERROR # @todo need to fix this
end

##
# Container for all the accessibility objects as well as core abstraction
# layer that that interact with OS X Accessibility APIs.
module AX; end

##
# @todo The current strategy dealing with errors is just to log them,
#       but that may not always be the correct thing to do. The core
#       has to be refactored around this issue to become more robust.
# @todo I feel a bit weird having to instantiate a new pointer every
#       time I want to fetch an attribute. Since allocations are costly
#       it hurts performance a lot when it comes to searches. I wonder if
#       it would pay off to have a pool of pointers...
#
# The singleton methods for the AX module represent the core layer of
# abstraction for AXElements.
#
# The methods provide a clean Ruby-ish interface to the low level
# CoreFoundation functions that compose the AXAPI. Doing this we can
# hide away the need to work with pointers and centralize when errors
# are logged from the low level function calls (since CoreFoundation
# uses a different pattern for that sort of thing).
class << AX

  # @group Attributes

  ##
  # List of attributes for the given element.
  #
  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def attrs_of_element element
    ptr = Pointer.new ARRAY_POINTER
    code = AXUIElementCopyAttributeNames(element, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # Number of elements that would be returned for the given element's
  # given attribute.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  # @return [Fixnum]
  def attr_count_of_element element, attr
    ptr  = Pointer.new :long_long
    code = AXUIElementGetAttributeValueCount(element, attr, ptr)
    log_error element, attr unless code.zero?
    ptr[0]
  end

  ##
  # Fetch the given attribute's value from the given element. You will
  # be given raw data from this method; that is, {Boxed} objects will
  # still be wrapped in a `AXValueRef`, and elements will be
  # `AXUIElementRef` objects.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def attr_of_element element, attr
    ptr  = Pointer.new :id
    code = AXUIElementCopyAttributeValue(element, attr, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # @todo Should we handle cases where a subrole has a value of
  #       'Unknown'? What is the performance impact?
  #
  # Fetch subrole and role of an object, pass back an array with the
  # subrole first if it exists.
  #
  # @param [AXUIElementRef]
  # @param [Array<String>]
  # @return [Array<String>] subrole first, if it exists
  def role_for element, attrs
    ptr = Pointer.new :id
    AXUIElementCopyAttributeValue(element, ROLE, ptr)
    ret = [ptr[0]]
    if attrs.include? SUBROLE
      AXUIElementCopyAttributeValue(element, SUBROLE, ptr)
      # Be careful, some things claim to have a subrole but return nil
      ret.unshift ptr[0] if ptr[0]
    end
    ret
    #raise "Found an element that has no role: #{CFShow(element)}"
  end

  ##
  # Whether or not the given attribute of a given element can be
  # changed using the accessibility APIs.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def attr_of_element_writable? element, attr
    ptr  = Pointer.new :bool
    code = AXUIElementIsAttributeSettable(element, attr, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # @note This method does not check writability of the attribute
  #       you are setting.
  #
  # Set the given value to the given attribute of the given element.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  # @param [Object] value the new value to set on the attribute
  # @return [Object] returns the value that was set
  def set_attr_of_element element, attr, value
    code = AXUIElementSetAttributeValue(element, attr, value)
    log_error element, code unless code.zero?
    value
  end

  # @group Actions

  ##
  # List of actions that the given element can perform.
  #
  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def actions_of_element element
    array_ptr = Pointer.new ARRAY_POINTER
    code = AXUIElementCopyActionNames(element, array_ptr)
    log_error element, code unless code.zero?
    array_ptr[0]
  end

  ##
  # Trigger the given action for the given element.
  #
  # @param [AXUIElementRef] element
  # @param [String] action an action constant
  # @return [Boolean] true if successful
  def action_of_element element, action
    code = AXUIElementPerformAction(element, action)
    code.zero? ? true : (log_error(element, code); false)
  end

  ##
  # In cases where you need (or want) to simulate keyboard input, such as
  # triggering hotkeys, you will need to use this method.
  #
  # See the documentation page on
  # {file:docs/KeyboardEvents.markdown Keyboard Events}
  # to get a detailed explanation on how to encode strings.
  #
  # @param [AXUIElementRef] element an application to post the event to, or
  #   the system wide accessibility object
  # @param [String] string the string you want typed on the screen
  def keyboard_action element, string
    post_kb_events element, parse_kb_string(string)
    nil
  end

  # @group Parameterized Attributes

  ##
  # List of parameterized attributes for the given element.
  #
  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def param_attrs_of_element element
    array_ptr = Pointer.new ARRAY_POINTER
    code = AXUIElementCopyParameterizedAttributeNames(element, array_ptr)
    log_error element, code unless code.zero?
    array_ptr[0]
  end

  ##
  # Fetch the given attribute's value from the given element using the given
  # parameter. You will be given raw data from this method; that is, {Boxed}
  # objects will still be wrapped in a `AXValueRef`, etc.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def param_attr_of_element element, attr, param
    ptr  = Pointer.new :id
    code = AXUIElementCopyParameterizedAttributeValue(element, attr, param, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  # @group Notifications

  ##
  ##
  # @todo This method is too big, might be hard to understand...
  #
  # {file:docs/Notifications.markdown Notifications} are a way to put
  # non-polling delays into your scripts.
  #
  # Register to be notified of a specified event in an application.
  #
  # You can optionally pass a block to this method to validate the
  # notification.
  #
  # @param [AXUIElementRef] element the element which will send the notification
  # @param [String] notif the name of the notification
  # @yield Validate the notification; the block should return truthy if
  #        the notification received is the expected one and the script can stop
  #        waiting, otherwise should return falsy.
  # @yieldparam [AXUIElementRef] element the element that sent the notification
  # @yieldparam [String] notif the name of the notification
  # @yieldreturn [Boolean] determines if the script should continue or wait
  # @return [Proc] the proc used as a callback when the notification is received
  def register_for_notif element, notif, &blk
    notif_proc = Proc.new do |obsrvr, elmnt, ntfctn, _|
      break unless blk ? blk.call(elmnt, ntfctn) : true
      run_loop   = CFRunLoopGetCurrent()
      app_source = AXObserverGetRunLoopSource(obsrvr)
      CFRunLoopRemoveSource(run_loop, app_source, KCFRunLoopDefaultMode)
      CFRunLoopStop(run_loop)
    end

    observer   = make_observer_for element, notif_proc
    run_loop   = CFRunLoopGetCurrent()
    app_source = AXObserverGetRunLoopSource(observer)
    CFRunLoopAddSource(run_loop, app_source, KCFRunLoopDefaultMode)
    register_notif_callback observer, element, notif
    notif_proc
  end

  ##
  # @todo Handle failure cases gracefully; instead of just returning false,
  #       we need to unregister the notification so that it doesn't screw
  #       up future things.
  # @todo Prime candidate for robustness refactoring.
  #
  # Pause execution of the program until a notification is received or a
  # timeout occurs.
  #
  # @param [Float] timeout
  # @return [Boolean] true if the notification was received, otherwise false
  def wait_for_notif timeout
    # We use RunInMode because it has timeout functionality; this method
    # actually has 4 return values, but only two codes will occur under
    # regular circumstances.
    CFRunLoopRunInMode(KCFRunLoopDefaultMode, timeout, false) == 2
  end

  # @group Element Entry Points

  ##
  # This will give you the UI element located at the position given. If
  # more than one element is at the position then the z-order of the
  # elements will be used to determine which is "on top".
  #
  # The coordinates should be specified using the flipped coordinate
  # system (origin is in the top-left, increasing downward as if reading
  # a book in English).
  #
  # @param [Float] x
  # @param [Float] y
  # @return [AXUIElementRef]
  def element_at_point x, y
    ptr    = Pointer.new AX_POINTER
    system = AXUIElementCreateSystemWide()
    code   = AXUIElementCopyElementAtPosition(system, x, y, ptr)
    log_error system, code unless code.zero?
    ptr[0]
  end

  ##
  # You can call this method to create the application object given
  # the process identifier of the app.
  #
  # @param [Fixnum] pid process identifier for the application you want
  # @return [AXUIElementRef]
  def application_for_pid pid
    raise ArgumentError, 'pid must be greater than 0' unless pid > 0
    AXUIElementCreateApplication(pid)
  end

  # @group Misc.

  ##
  # Get the PID of the application that the given element belongs to.
  #
  # @param [AXUIElementRef] element
  # @return [Fixnum]
  def pid_of_element element
    ptr  = Pointer.new :int
    code = AXUIElementGetPid(element, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  # @endgroup


  private

  ##
  # @private
  #
  # Pointer type encoding for `CFArrayRef` objects
  #
  # @return [String]
  ARRAY_POINTER = NSString.stringWithString '^{__CFArray}'

  ##
  # @private
  #
  # Pointer type encoding for `AXUIElementRef` objects
  #
  # @return [String]
  AX_POINTER  = NSString.stringWithString '^{__AXUIElement}'

  ##
  # @private
  #
  # Pointer type encoding for `AXObserverRef` objects
  #
  # @return [String]
  AX_OBSERVER = NSString.stringWithString '^{__AXObserver}'

  ##
  # @private
  #
  # Local copy of a Cocoa constant; this is a performance hack
  #
  # @return [String]
  ROLE    = KAXRoleAttribute

  ##
  # @private
  #
  # Local copy of a Cocoa constant; this is a performance hack
  #
  # @return [String]
  SUBROLE = KAXSubroleAttribute


  require 'key_coder'

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
  # Post the list of given keyboard events to the given element.
  #
  # @param [AXUIElementRef] element must be an application or the
  #   system-wide object
  # @param [Array<Array(Number,Boolean)>]
  def post_kb_events element, events
    events.each do |event|
      code = AXUIElementPostKeyboardEvent(element, 0, *event)
      log_error element, code unless code.zero?
    end
  end

  ##
  # @private
  #
  # A mapping of the `AXError` constants to human readable strings, though
  # this has to be actively maintained in case of changes to Apple's
  # documentation in the future.
  #
  # @return [Hash{Fixnum=>String}]
  AXError = {
    KAXErrorFailure                           => 'Generic Failure',
    KAXErrorIllegalArgument                   => 'Illegal Argument',
    KAXErrorInvalidUIElement                  => 'Invalid UI Element',
    KAXErrorInvalidUIElementObserver          => 'Invalid UI Element Observer',
    KAXErrorCannotComplete                    => 'Cannot Complete',
    KAXErrorAttributeUnsupported              => 'Attribute Unsupported',
    KAXErrorActionUnsupported                 => 'Action Unsupported',
    KAXErrorNotificationUnsupported           => 'Notification Unsupported',
    KAXErrorNotImplemented                    => 'Not Implemented',
    KAXErrorNotificationAlreadyRegistered     => 'Notification Already Registered',
    KAXErrorNotificationNotRegistered         => 'Notification Not Registered',
    KAXErrorAPIDisabled                       => 'API Disabled',
    KAXErrorNoValue                           => 'No Value',
    KAXErrorParameterizedAttributeUnsupported => 'Parameterized Attribute Unsupported',
    KAXErrorNotEnoughPrecision                => 'Not Enough Precision'
  }

  ##
  # Uses the call stack and error code to log a message that might be
  # helpful in debugging.
  #
  # @param [AXUIElementRef] element
  # @param [Fixnum] code AXError value
  # @return [Fixnum] returns the code that was passed
  def log_error element, code
    message = AXError[code] || 'UNKNOWN ERROR CODE'
    logger = Accessibility.log
    logger.warn "[#{message} (#{code})] while trying #{caller[0]}"
    logger.info "Available attributes were:\n#{attrs_of_element(element)}"
    logger.info "Available actions were:\n#{actions_of_element(element)}"
    # @todo logger.info available parameterized attributes
    logger.debug "Backtrace: #{caller.description}"
    # @todo logger.debug pp hierarchy element or pp element
  end

  ##
  # Create and return a notification observer for the given object's
  # application.
  #
  # @param [AXUIElementRef] element
  # @param [Method,Proc] callback
  # @return [AXObserverRef]
  def make_observer_for element, callback
    ptr  = Pointer.new AX_OBSERVER
    code = AXObserverCreate(pid_of_element(element), callback, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # @todo Consider exposing the refcon argument. Probably not until
  #       someone actually wants to pass a context around.
  # @todo Need to cache a list of callbacks so that they can be unregistered
  #       in cases when an error occurs.
  #
  # Setup a callback for an accessibility notification.
  #
  # @param [AXObserverRef] observer
  # @param [AX::Element] element
  # @param [String] notif
  def register_notif_callback observer, element, notif
    code = AXObserverAddNotification(observer, element, notif, nil)
    log_error element, code unless code.zero?
  end

end
