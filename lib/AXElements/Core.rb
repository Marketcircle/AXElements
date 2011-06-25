##
# @todo The current strategy dealing with errors is just to log them,
#       but that may not always be the correct thing to do. This
#       requires some meditation.
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

  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def attrs_of_element element
    ptr = Pointer.new '^{__CFArray}'
    code = AXUIElementCopyAttributeNames(element, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # Fetch the data from an attribute and process it into something
  # useful.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def attr_of_element element, attr
    process_ax_data raw_attr_of_element(element, attr)
  end

  ##
  # Check if an attribute of an element is writable.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def attr_of_element_writable? element, attr
    ptr  = Pointer.new 'B'
    code = AXUIElementIsAttributeSettable(element, attr, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # Set the value of an attribute. This method does not check
  # if the attribute is writable.
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

  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def actions_of_element element
    array_ptr = Pointer.new '^{__CFArray}'
    code = AXUIElementCopyActionNames(element, array_ptr)
    log_error element, code unless code.zero?
    array_ptr[0]
  end

  ##
  # Trigger and action that an element can perform.
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
  # @param [AXUIElementRef] element an application to post the event to
  # @param [String] string the string you want typed on the screen
  def keyboard_action element, string
    post_kb_events(element, parse_kb_string(string))
    nil
  end

  # @group Parameterized Attributes

  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>,nil] nil if the element has no
  #   parameterized attributes
  def param_attrs_of_element element
    array_ptr = Pointer.new '^{__CFArray}'
    code = AXUIElementCopyParameterizedAttributeNames(element, array_ptr)
    log_error element, code unless code.zero?
    array_ptr[0]
  end

  ##
  # Fetch the data from a parameterized attribute and process it into
  # something useful.
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def param_attr_of_element element, attr, param
    process_ax_data raw_param_attr_of_element(element, attr, param)
  end

  # @group Notifications

  ##
  # @todo Provide an interface that takes a PID instead of an element?
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
  # @yieldparam [AX::Element] element the element that sent the notification
  # @yieldparam [String] notif the name of the notification
  # @yieldreturn [Boolean] determines if the script should continue or wait
  # @return [Proc] the proc used as a callback when the notification is received
  def register_for_notif element, notif, &blk
    notif_proc = Proc.new do |obsrvr, elmnt, ntfctn, _|
      wrapped_elmnt = element_attribute elmnt
      stop_waiting  = blk ? blk.call(wrapped_elmnt, ntfctn) : true
      break unless stop_waiting

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
  #
  # Pause execution of the program until a notification is received or a
  # timeout occurs.
  #
  # We use RunInMode because it has timeout functionality; this method
  # actually has 4 return values, but only two codes will occur under
  # regular circumstances.
  #
  # @param [Float] timeout
  # @return [Boolean] true if the notification was received, otherwise false
  def wait_for_notif timeout
    CFRunLoopRunInMode(KCFRunLoopDefaultMode, timeout, false) == 2
  end

  # @group Dynamic Elements

  ##
  # This will give you the UI element located at the position given (if
  # there is one). If more than one element is at the position then the
  # z-order of the elements will be used to determine which is "on top".
  #
  # The co-ordinates should be specified with the origin being in the
  # top-left corner of the main screen.
  #
  # @param [Float] x
  # @param [Float] y
  # @return [AX::Element]
  def element_at_point x, y
    ptr     = Pointer.new '^{__AXUIElement}'
    system  = AXUIElementCreateSystemWide()
    code    = AXUIElementCopyElementAtPosition(system, x, y, ptr)
    log_error system, code unless code.zero?
    element_attribute ptr[0]
  end

  ##
  # You can call this method to create the application object if the
  # app is already running; otherwise the object creation will fail.
  #
  # @param [Fixnum] pid The process identifier for the application you want
  # @return [AX::Application]
  def application_for_pid pid
    AX::Application.new AXUIElementCreateApplication(pid)
  end

  # @group Misc.

  ##
  # Get the PID of the application that an element belongs to.
  #
  # @param [AXUIElementRef] element
  # @return [Fixnum]
  def pid_of_element element
    ptr  = Pointer.new( 'i' )
    code = AXUIElementGetPid(element, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # @note In the case of a predicate name, this will strip the 'Is'
  #       part of the name if it is present
  #
  # Takes an accessibility constant and returns a new string with the
  # namespace prefix removed.
  #
  # @example
  #
  #   AX.strip_prefix 'AXTitle'                    # => 'Title'
  #   AX.strip_prefix 'AXIsApplicationEnabled'     # => 'ApplicationEnabled'
  #   AX.strip_prefix 'MCAXEnabled'                # => 'Enabled'
  #   AX.strip_prefix KAXWindowCreatedNotification # => 'WindowCreated'
  #   AX.strip_prefix NSAccessibilityButtonRole    # => 'Button'
  #
  # @param [String] constant
  # @return [String]
  def strip_prefix constant
    constant.sub(/^[A-Z]*?AX(?:Is)?/, '')
  end

  # @endgroup


  private

  # @todo Extract data from /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h
  # Map keyboard characters to their keycodes
  # @return [Hash{String=>Fixnum}]
  KEYCODE_MAP = {
    # Letters
    'a' => 0,  'b' => 11, 'c' => 8,  'd' => 2,  'e' => 14, 'f' => 3,
    'g' => 5,  'h' => 4,  'i' => 34, 'j' => 38, 'k' => 40, 'l' => 37,
    'm' => 46, 'n' => 45, 'o' => 31, 'p' => 35, 'q' => 12, 'r' => 15,
    's' => 1,  't' => 17, 'u' => 32, 'v' => 9,  'w' => 13, 'x' => 7,
    'y' => 16, 'z' => 6,
    # Numbers
    '1' => 18, '2' => 19, '3' => 20, '4' => 21, '5' => 23, '6' => 22,
    '7' => 26, '8' => 28, '9' => 25, '0' => 29,
    # Misc.
    "\t" => 48, ' ' => 49, "\e"=> 53,"\b"=> 51, "\s"=> 49, "\n"=> 36,
    "\r" => 36
  }

  def parse_kb_string string
    sequence = []
    string.each_char do |char|
      if char.match(/[A-Z]/)
        code  = KEYCODE_MAP[char.downcase]
        event = [[56,true], [code,true], [code,false], [56,false]]
      else
        code  = KEYCODE_MAP[char]
        event = [[code,true],[code,false]]
      end
      sequence.concat event
    end
    sequence
  end

  def post_kb_events element, events
    events.each do |event|
      code = AXUIElementPostKeyboardEvent(element, 0, *event)
      log_error element, code unless code.zero?
    end
  end

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
  # A mapping of the AXError constants to human readable strings, though
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
  # @todo AXUIElementCopyMultipleAttributeValues could be used
  #       to speed up access if we turn the second argument into
  #       a vararg
  #
  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def raw_attr_of_element element, attr
    ptr  = Pointer.new(:id)
    code = AXUIElementCopyAttributeValue( element, attr, ptr )
    log_error element, code unless code.zero?
    ptr[0]
  end

  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def raw_param_attr_of_element element, attr, param
    ptr  = Pointer.new(:id)
    code = AXUIElementCopyParameterizedAttributeValue( element, attr, param, ptr )
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # Takes a return value from {#raw_attr_of_element} and, if required,
  # converts the data to something more usable.
  #
  # Generally, used to process an AXValue into a CGPoint or an
  # AXUIElementRef into some kind of AX::Element object.
  def process_ax_data value
    return if value.nil?
    id = ATTR_MASSAGERS[CFGetTypeID(value)]
    id ? self.send(id, value) : value
  end

  ##
  # Mapping low level type ID numbers to methods to massage useful
  # objects from data.
  #
  # @return [Array<Symbol>]
  ATTR_MASSAGERS = []
  ATTR_MASSAGERS[AXUIElementGetTypeID()] = :element_attribute
  ATTR_MASSAGERS[CFArrayGetTypeID()]     = :array_attribute
  ATTR_MASSAGERS[AXValueGetTypeID()]     = :boxed_attribute

  ##
  # Creates new class at run time and puts it into the {AX} namespace.
  # This method is called for each type of UI element that has not yet been
  # explicitly defined so that they can be defined them at runtime.
  #
  # @param [String,Symbol] name
  # @param [String,Symbol] superklass
  # @return [Class]
  def create_ax_class name, superklass = :Element
    real_superklass = determine_class_for([superklass])
    klass = Class.new(real_superklass) {
      Accessibility.log.debug "#{name} class created"
    }
    const_set name, klass
  end

  ##
  # @todo Could we use regular #const_get and add #const_missing instead?
  #
  # Like #const_get except that if the class does not exist yet then
  # it will assume the constant belongs to a class and creates the class
  # for you.
  #
  # @param [Array<String>] const the value you want as a constant
  # @return [Class] a reference to the class being looked up
  def determine_class_for names
    const = names.first
    const_defined?(const) ? const_get(const) : create_ax_class(*names)
  end

  ##
  # @todo Should we handle cases where a subrole has a value of
  #       'Unknown'? What is the performance impact?
  #
  # Fetch subrole and role of an object, pass back a clean array of strings.
  #
  # We have to be careful, because some things claim to have a subrole
  # but return nil or they have a subrole value of 'Unknown'.
  #
  # @param [AXUIElementRef]
  # @return [Array<String>] subrole first, if it exists
  def roles_for element
    ptr  = Pointer.new :id
    aptr = Pointer.new '^{__CFArray}'
    AXUIElementCopyAttributeValue(element, ROLE, ptr)
    ret = [ptr[0]]
    AXUIElementCopyAttributeNames(element, aptr)
    if aptr[0].include? SUBROLE
      AXUIElementCopyAttributeValue(element, SUBROLE, ptr)
      ret.unshift ptr[0]
    end
    ret
    #raise "Found an element that has no role: #{CFShow(element)}"
  end

  # @return [String] local copy of a Cocoa constant; this is a performance hack
  ROLE    = KAXRoleAttribute
  # @return [String] local copy of a Cocoa constant; this is a performance hack
  SUBROLE = KAXSubroleAttribute

  ##
  # Takes an AXUIElementRef and gives you some kind of accessibility object.
  #
  # @param [AXUIElementRef] element
  # @return [Element]
  def element_attribute element
    names = roles_for(element).map! { |x| strip_prefix x }
    determine_class_for(names).new(element)
  end

  ##
  # @todo Consider mapping in all cases to avoid returning a CFArray
  #
  # We assume a homogeneous array.
  #
  # @return [Array,nil]
  def array_attribute vals
    return vals if vals.empty? || !ATTR_MASSAGERS[CFGetTypeID(vals.first)]
    vals.map { |val| element_attribute val }
  end

  # @return [Class,nil] order-sensitive (i.e. why index 0 is nil)
  AXBoxType = [ nil, CGPoint, CGSize, CGRect, CFRange ]

  ##
  # Find out what type of struct is contained in the AXValueRef and then
  # wrap it properly.
  #
  # @param [AXValueRef] value
  # @return [Boxed,nil]
  def boxed_attribute value
    return unless value
    box_type = AXValueGetType(value)
    ptr      = Pointer.new(AXBoxType[box_type].type)
    AXValueGetValue(value, box_type, ptr)
    ptr[0]
  end

  ##
  # Create and return a notification observer for the object's application.
  #
  # @param [AXUIElementRef] element
  # @param [Method,Proc] callback
  # @return [AXObserverRef]
  def make_observer_for element, callback
    ptr  = Pointer.new '^{__AXObserver}'
    code = AXObserverCreate(pid_of_element(element), callback, ptr)
    log_error element, code unless code.zero?
    ptr[0]
  end

  ##
  # @todo Consider exposing the refcon argument
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
