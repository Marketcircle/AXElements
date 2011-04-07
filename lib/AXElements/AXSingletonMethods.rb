##
# Wrappers around the lower level AXUIElement functions.
class << AX

  # @todo Should this be private?
  # @return [Regexp]
  attr_reader :prefix

  # @group Attributes

  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def attrs_of_element element
    array_ptr = Pointer.new( '^{__CFArray}' )
    code = AXUIElementCopyAttributeNames( element, array_ptr )
    log_ax_call element, code
    array_ptr[0]
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
    ptr  = Pointer.new('B')
    code = AXUIElementIsAttributeSettable( element, attr, ptr )
    log_ax_call element, code
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
    code = AXUIElementSetAttributeValue( element, attr, value )
    log_ax_call element, code
    value
  end

  # @group Actions

  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>]
  def actions_of_element element
    array_ptr = Pointer.new( '^{__CFArray}' )
    code = AXUIElementCopyActionNames( element, array_ptr )
    log_ax_call element, code
    array_ptr[0]
  end

  ##
  # Preform an action on an element.
  #
  # @param [AXUIElementRef] element
  # @param [String] action an action constant
  # @return [Boolean] true if successful
  def perform_action_of_element element, action
    code = AXUIElementPerformAction( element, action )
    log_ax_call( element, code ) == 0
  end

  ##
  # @todo look at CGEventKeyboardSetUnicodeString for posting events
  #       without needing the keycodes
  # @todo look at UCKeyTranslate for working with different keyboard
  #       layouts
  # @todo a small parser to generate the actual sequence of key presses to
  #       simulate. Most likely just going to extend built in string escape
  #       sequences if possible
  # @todo Move this out, or mirror it, in Kernel
  # @note This method only handles lower case letters, spaces, tabs, and
  #       the escape key right now.
  #
  # In cases where you need (or want) to simulate keyboard input, such as
  # triggering hotkeys, you will need to use this method.
  #
  # See the documentation page [KeyboardEvents](file/KeyboardEvents.markdown)
  # on how to encode strings, as well as other details on using methods
  # from this module.
  #
  # @param [AXUIElementRef] element an application to post the event to
  # @param [String] string the string you want typed on the screen
  # @return [Boolean] true unless something goes horribly wrong
  def post_kb_string element, string
    string.each_char { |char|
      key_code = KEYCODE_MAP[char]
      code = AXUIElementPostKeyboardEvent(element, 0, key_code, true)
      log_ax_call element, code
      code = AXUIElementPostKeyboardEvent(element, 0, key_code, false)
      log_ax_call element, code
    }
    true
  end

  # @group Parameterized Attributes

  # @param [AXUIElementRef] element low level accessibility object
  # @return [Array<String>,nil] nil if the element has no
  #   parameterized attributes
  def param_attrs_of_element element
    array_ptr = Pointer.new( '^{__CFArray}' )
    code = AXUIElementCopyParameterizedAttributeNames( element, array_ptr )
    log_ax_call element, code
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
  # @todo turn this into a proc and dispatch it from within
  #       the {#wait_for_notification} method (waiting on MacRuby bug),
  #       or move this method to its own class
  # @todo desperately needs refactoring
  #
  # Do not call this method directly. It will be called automatically
  # when a notification is triggered.
  #
  # @param [AXObserverRef] observer the observer being notified
  # @param [AXUIElementRef] element the element being referenced
  # @param [String] notif the notification name
  # @param [Object] refcon some context object that you can pass around
  def notif_method observer, element, notif, refcon
    should_stop_waiting   = true
    if @notif_proc
      should_stop_waiting = @notif_proc.call(process_ax_data(element), notif)
      @notif_proc         = nil
    end
    return unless should_stop_waiting

    run_loop   = CFRunLoopGetCurrent()
    app_source = AXObserverGetRunLoopSource( observer )
    CFRunLoopRemoveSource( run_loop, app_source, KCFRunLoopDefaultMode )
    CFRunLoopStop(run_loop)
  end

  ##
  # @todo kAXUIElementDestroyedNotification look at it for catching
  #       windows that disappear
  # @todo mirror this method in Kernel
  # @note This method is not thread safe right now
  #
  # [Notifications](../../file/Notifications.markdown) are a way to put
  # non-polling delays into your scripts (sorta).
  #
  # Pause execution of the program until a notification is received or a
  # timeout occurs.
  #
  # You can optionally pass a block to this method to validate the
  # notification.
  #
  # @param [String] notif the name of the notification
  # @param [Float] timeout
  # @yield Validate the notification; the block should return truthy if
  #        the notification is expected and the script can stop waiting,
  #        otherwise should return falsy.
  # @yieldparam [AX::Element] element the element that sent the notification
  # @yieldparam [String] notif the name of the notification
  # @yieldreturn [Boolean] determines if the script should continue or wait
  # @return [Boolean] true if the notification was received, otherwise false
  def wait_for_notification element, notif, timeout
    @notif_proc = Proc.new if block_given?
    observer    = notification_observer element, method(:notif_method)

    run_loop     = CFRunLoopGetCurrent()
    app_run_loop = AXObserverGetRunLoopSource( observer )

    register_notif_callback( observer, element, notif )
    CFRunLoopAddSource( run_loop, app_run_loop, KCFRunLoopDefaultMode )

    # use RunInMode because it has timeout functionality; this method
    # actually has 4 return values, but only two codes will occur under
    # regular circumstances
    CFRunLoopRunInMode( KCFRunLoopDefaultMode, timeout, false ) == 2
  end

  # @group Dynamic Elements

  ##
  # Finds the current mouse position and then calls {#element_at_position}.
  #
  # @return [AX::Element]
  def element_under_mouse
    element_at_position NSEvent.mouseLocation.carbonize!
  end

  ##
  # This will give you the UI element located at the position given (if
  # there is one). If more than one element is at the position then the
  # z-order of the elements will be used to determine which is "on top".
  #
  # The co-ordinates should be specified with the origin being in the
  # top-left corner of the main screen.
  #
  # @param [CGPoint] point
  # @return [AX::Element]
  def element_at_position point
    ptr     = Pointer.new( '^{__AXUIElement}' )
    system  = AXUIElementCreateSystemWide()
    code    = AXUIElementCopyElementAtPosition( system, point.x, point.y, ptr )
    log_ax_call system, code
    element_attribute ptr[0]
  end

  ##
  # Get a list of elements, starting with the element you gave and riding
  # all the way up the hierarchy to the top level (should be the Application).
  #
  # @param [AX::Element] element
  # @return [Array<AX::Element>] the hierarchy in ascending order
  def hierarchy *elements
    element = elements.last
    return hierarchy(elements << element.parent) if element.respond_to?(:parent)
    return elements
  end

  ##
  # You can call this method to create the application object if the
  # app is already running; otherwise the object creation will fail.
  #
  # @param [Fixnum] pid The process identifier for the application you want
  # @return [AX::Application]
  def application_for_pid pid
    element_attribute( AXUIElementCreateApplication(pid) )
  end

  ##
  # @todo Find a way for this method to work without sleeping;
  #       consider looping begin/rescue/end until AX starts up
  # @todo Search NSWorkspace.sharedWorkspace.runningApplications ?
  # @todo add another app launching method using app names
  #
  # This is the standard way of creating an application object. It will
  # launch the app if it is not already running and then create the
  # accessibility object.
  #
  # However, this method is a HUGE hack in cases where the app is not
  # already running; I've tried to register for notifications, launch
  # synchronously, etc., but there is always a problem with accessibility
  # not being ready. Hopefully this problem will go away on Lion...
  #
  # @param [String] bundle
  # @param [Float] timeout how long to wait between polling
  # @return [AX::Application]
  def application_with_bundle_identifier bundle, sleep_time
    while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
      launch_application bundle
      sleep sleep_time
    end
    application_for_pid( apps.first.processIdentifier )
  end

  # @group Misc.

  ##
  # @todo consider using the rails inflector
  #
  # Chomps off a trailing 's' if there is one and then looks up the constant.
  #
  # @param [#to_s] const
  # @return [Class,nil] the class if it exists, else returns nil
  def plural_const_get const
    const = const.to_s.chomp 's'
    return const_get const if const_defined? const
  end

  ##
  # Get the PID of the application that an element belongs to.
  #
  # @param [AXUIElementRef] element
  # @return [Fixnum]
  def pid_of_element element
    ptr  = Pointer.new 'i'
    code = AXUIElementGetPid( @ref, ptr )
    log_ax_call element, code
    ptr[0]
  end

  # @endgroup


  private

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
    "\t" => 48, ' ' => 49, "\e"=> 53
  }

  ##
  # @todo print view hierarchy using {Element#pretty_print}
  #
  # Uses the call stack and error code to log a message that might be
  # helpful in debugging.
  #
  # @param [AXUIElementRef] element
  # @param [Fixnum] code AXError value
  # @return [Fixnum] returns the code that was passed
  def log_ax_call element, code
    return code if code.zero?
    message = AXError[code] || 'UNKNOWN ERROR CODE'
    log.warn "[#{message} (#{code})] while trying #{caller[0]}"
    log.info "Available attrs/actions were:\n#{attrs_of_element(element)}\n#{actions_of_element(element)}"
    log.debug "Backtrace: #{caller.description}"
    code
  end

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
    log_ax_call element, code
    ptr[0]
  end

  # @param [AXUIElementRef] element
  # @param [String] attr an attribute constant
  def raw_param_attr_of_element element, attr, param
    ptr  = Pointer.new(:id)
    code = AXUIElementCopyParameterizedAttributeValue( element, attr, param, ptr )
    log_ax_call element, code
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
  # A mapping of the AXError constants to human readable strings.
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
  # Creates new class at run time and puts it into the {AX} namespace.
  # This method is called for each type of UI element that has not yet been
  # explicitly defined to define them at runtime.
  #
  # @param [#to_sym] class_name
  # @return [Class]
  def create_ax_class class_name
    klass = Class.new(Element) {
      AX.log.debug "#{class_name} class created"
    }
    const_set( class_name, klass )
  end

  ##
  # Like {#const_get} except that if the class does not exist yet then
  # it will create the class for you. If not used carefully, it could end
  # up creating a bunch of useless, possibly harmful, classes at run time.
  #
  # @param [#to_sym] const the value you want as a constant
  # @return [Class] a reference to the class being looked up
  def new_const_get const
    return const_get const if const_defined? const
    create_ax_class const
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
  # Figures out what the name of the class of an element should be.
  # We have to be careful, because some things claim to have a subrole
  # but return nil.
  #
  # This method prefers to choose a class type based on the subrole value for
  # an accessibility object, and it will use the role if there is no subrole.
  #
  # @param [AXUIElementRef]
  # @return [String]
  def class_name element
    attrs = attrs_of_element(element)
    [KAXSubroleAttribute,KAXRoleAttribute].map { |attr|
      if attrs.include?(attr)
          value = raw_attr_of_element(element, attr)
        return value if value
      end
    }
  end

  ##
  # Takes an AXUIElementRef and gives you some kind of accessibility object.
  #
  # @param [AXUIElementRef] element
  # @return [Element]
  def element_attribute element
    klass = class_name(element).sub(@prefix) { $1 }
    new_const_get(klass).new(element)
  end

  ##
  # @todo Consider mapping in all cases to avoid returning a CFArray
  #
  # We assume a homogeneous array.
  #
  # @return [Array,nil]
  def array_attribute vals
    return vals if vals.empty? || (ATTR_MASSAGERS[CFGetTypeID(vals.first)] == 1)
    vals.map { |val| element_attribute val }
  end

  ##
  # This array is order-sensitive, which is why there is a
  # nil object at index 0.
  #
  # @return [Class,nil]
  AXBoxType = [ nil, CGPoint, CGSize, CGRect, CFRange ]

  # @return [Boxed,nil]
  def boxed_attribute value
    return unless value
    box_type = AXValueGetType( value )
    ptr      = Pointer.new( AXBoxType[box_type].type )
    AXValueGetValue( value, box_type, ptr )
    ptr[0]
  end

  ##
  # Create and return a notification observer for the object's application.
  # This method is almost never directly called, it is instead called by
  # {Traits::Notifications#wait_for_notification}.
  #
  # @param [Method,Proc] callback
  # @return [AXObserverRef]
  def notification_observer element, callback
    ptr  = Pointer.new '^{__AXObserver}'
    code = AXObserverCreate( pid_of_element(element), callback, ptr )
    log_ax_call element, code
    ptr[0]
  end

  ##
  # @todo Consider exposing the refcon argument
  #
  # Setup a callback for an accessibility notification.
  #
  # @param [AXObserverRef] observer
  # @param [AX::Element] element
  # @param [String] notif
  def register_notif_callback observer, element, notif
    code = AXObserverAddNotification( observer, element, notif, nil )
    log_ax_call element, code
  end

end
