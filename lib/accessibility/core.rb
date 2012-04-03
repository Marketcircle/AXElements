# -*- coding: utf-8 -*-

framework 'Cocoa'

# check that the Accessibility APIs are enabled and are available to MacRuby
begin
  unless AXAPIEnabled()
    raise RuntimeError, <<-EOS
------------------------------------------------------------------------
Universal Access is disabled on this machine.

Please enable it in the System Preferences.
------------------------------------------------------------------------
    EOS
  end
rescue NoMethodError
  raise NotImplementedError, <<-EOS
------------------------------------------------------------------------
You need to install the latest BridgeSupport preview so that AXElements
has access to CoreFoundation.
------------------------------------------------------------------------
  EOS
end


require 'accessibility/version'

##
# @todo I feel a bit weird having to instantiate a new pointer every
#       time I want to fetch an attribute. Since allocations are costly,
#       it hurts performance a lot when it comes to searches. I wonder if
#       it would pay off to have a pool of pointers...
#
# Core abstraction layer that that interacts with OS X Accessibility
# APIs (AXAPI). This is actually just a mixin for `AXUIElementRef` objects
# so that they become more object oriented.
#
# This module is responsible for handling pointers and dealing with error
# codes for functions that make use of them. The methods in this module
# provide a clean Ruby-ish interface to the low level CoreFoundation
# functions that compose AXAPI. In doing this, we can hide away the need
# to work with pointers and centralize how AXAPI related errors are handled
# (since CoreFoundation uses a different pattern for that sort of thing).
#
# @example
#
#   element = AXUIElementCreateSystemWide()
#   element.attributes                      # => ["AXRole", "AXChildren", ...]
#   element.size_of "AXChildren"            # => 12
#
module Accessibility::Core


  # @group Attributes

  ##
  # @todo Invalid elements do not always raise an error.
  #       This is a bug that should be logged with Apple.
  #
  # Get the list of attributes for the element. As a convention, this
  # method will return an empty array if the backing element is no longer
  # alive.
  #
  # @example
  #
  #   attributes # => ["AXRole", "AXRoleDescription", ...]
  #
  # @return [Array<String>]
  def attributes
    @attributes ||= (
      ptr = Pointer.new ARRAY
      case code = AXUIElementCopyAttributeNames(self, ptr)
      when 0                        then ptr.value
      when KAXErrorInvalidUIElement then []
      else handle_error code
      end
      )
  end

  ##
  # Fetch the value for an attribute. CoreFoundation wrapped objects
  # will be unwrapped for you, if you expect to get a {CFRange} you
  # will be given a {Range} instead.
  #
  # As a convention, if the backing element is no longer alive then
  # you will receive `nil` for any attribute.
  #
  # @example
  #   attribute KAXTitleAttribute   # => "HotCocoa Demo"
  #   attribute KAXSizeAttribute    # => #<CGSize width=10.0 height=88>
  #   attribute KAXParentAttribute  # => #<AXUIElementRef>
  #   attribute KAXNoValueAttribute # => nil
  #
  # @param [String] name an attribute constant
  def attribute name
    ptr = Pointer.new :id
    case code = AXUIElementCopyAttributeValue(self, name, ptr)
    when 0               then ptr.value.to_ruby
    when KAXErrorNoValue then nil
    when KAXErrorInvalidUIElement
      name == KAXChildrenAttribute ? [] : nil
    when KAXErrorFailure
      name == KAXChildrenAttribute ? [] : handle_error(code, name)
    else handle_error code, name
    end
  end

  ##
  # Shortcut for getting the `KAXRoleAttribute`.
  #
  # @example
  #
  #   role  # => KAXWindowRole
  #
  # @return [String]
  def role
    attribute KAXRoleAttribute
  end

  ##
  # @note You might get `nil` back as the subrole as AXWebArea
  #       objects are known to do this. You need to check. :(
  #
  # Shortcut for getting the `KAXSubroleAttribute`.
  #
  # @example
  #   subrole  # => "AXDialog"
  #   subrole  # => nil
  #
  # @return [String,nil]
  def subrole
    attribute KAXSubroleAttribute
  end

  ##
  # Shortcut for getting the `KAXChildrenAttribute`.
  #
  # @example
  #
  #   children # => [MenuBar, Window, ...]
  #
  # @return [Array<AX::Element>]
  def children
    attribute KAXChildrenAttribute
  end

  ##
  # Shortcut for getting the `KAXValueAttribute`.
  #
  # @example
  #
  #   value  # => "Mark Rada"
  #   value  # => 42
  #
  def value
    attribute KAXValueAttribute
  end

  ##
  # Get the size of the array for attributes that would return an array.
  # When performance matters, this is much faster than getting the array
  # and asking for the size.
  #
  # If there is a failure or the backing element is no longer alive, this
  # method will return `0`.
  #
  # @example
  #
  #   size_of KAXChildrenAttribute  # => 19
  #   size_of KAXRowsAttribute      # => 100
  #
  # @param [String] name an attribute constant
  # @return [Number]
  def size_of name
    ptr = Pointer.new :long_long
    case code = AXUIElementGetAttributeValueCount(self, name, ptr)
    when 0                                                  then ptr.value
    when KAXErrorFailure, KAXErrorAttributeUnsupported,
      KAXErrorInvalidUIElement                              then 0
    else handle_error code, name
    end
  end

  ##
  # Returns whether or not an attribute is writable.
  #
  # @example
  #
  #   writable? KAXSizeAttribute  # => true
  #   writable? KAXTitleAttribute # => false
  #
  # @param [String] name an attribute constant
  def writable? name
    ptr = Pointer.new :bool
    case code = AXUIElementIsAttributeSettable(self, name, ptr)
    when 0                        then ptr.value
    when KAXErrorInvalidUIElement then false
    else handle_error code, name
    end
  end

  ##
  # @note This method does not check writability of the attribute
  #       you are setting. If you need to check, use {#writable?}
  #       first.
  #
  # Set the given value to the given attribute. You do not need to
  # worry about wrapping objects first, `Range` objects will also
  # be automatically converted into `CFRange` objects and then
  # wrapped.
  #
  # Unlike when reading attributes, writing to a dead element will
  # raise an exception.
  #
  # @example
  #   set KAXValueAttribute,        "hi"       # => "hi"
  #   set KAXSizeAttribute,         [250,250]  # => [250,250]
  #   set KAXVisibleRangeAttribute, 0..-3      # => 0..-3
  #
  # @param [String] name an attribute constant
  def set name, value
    code = AXUIElementSetAttributeValue(self, name, value.to_ax)
    return value if code.zero?
    handle_error code, name, value
  end


  # @group Parameterized Attributes

  ##
  # Get the list of parameterized attributes for the element. If the
  # element does not have parameterized attributes, then an empty
  # list will be returned.
  #
  # Most elements do not have parameterized attributes, but the ones
  # that do, have many.
  #
  # @example
  #
  #   parameterized_attributes  # => ["AXStringForRange", ...]
  #   parameterized_attributes  # => []
  #
  # @return [Array<String>]
  def parameterized_attributes
    @parameterized_attributes ||= (
      ptr = Pointer.new ARRAY
      case code = AXUIElementCopyParameterizedAttributeNames(self, ptr)
      when 0                                         then ptr.value
      when KAXErrorNoValue, KAXErrorInvalidUIElement then []
      else handle_error code
      end
      )
  end

  ##
  # Fetch the given pramaeterized attribute value using the given parameter.
  # Only `AXUIElementRef` objects will be given raw, `Boxed` objects will be
  # unwrapped for you automatically and `CFRange` objects will be turned into
  # `Range` objects. Similarly, you do not need to worry about wrapping the
  # parameter as that will be done for you.
  #
  # @example
  #
  #   attribute KAXStringForRangeParameterizedAttribute, for_param: 1..10
  #     # => "ello, worl"
  #
  # @param [String] attr an attribute constant
  # @param [Object] param
  def attribute name, for_parameter: param
    ptr   = Pointer.new :id
    param = param.to_ax
    case code = AXUIElementCopyParameterizedAttributeValue(self,name,param,ptr)
    when 0                                         then ptr.value.to_ruby
    when KAXErrorNoValue, KAXErrorInvalidUIElement then nil
    else handle_error code, name, param
    end
  end


  # @group Actions

  ##
  # Get the list of actions that the element can perform. If an element
  # does not have actions, then an empty list will be returned.
  # Dead elements will also return an empty array.
  #
  # @example
  #
  #   action_names  # => ["AXPress"]
  #
  # @return [Array<String>]
  def actions
    @actions ||= (
      ptr = Pointer.new ARRAY
      case code = AXUIElementCopyActionNames(self, ptr)
      when 0                        then ptr.value
      when KAXErrorInvalidUIElement then []
      else handle_error code
      end
      )
  end

  ##
  # Ask an element to perform the given action. This method will always
  # return true or raise an exception. Actions should never fail.
  #
  # Unlike when reading attributes, performing an action on a dead element
  # will raise an exception.
  #
  # @example
  #
  #   perform KAXPressAction  # => true
  #
  # @param [String] action an action constant
  # @return [Boolean]
  def perform action
    code = AXUIElementPerformAction(self, action)
    return true if code.zero?
    handle_error code, action
  end

  ##
  # Post the list of given keyboard events to the element. This only
  # applies if the given element is an application object or the
  # system wide object.
  #
  # Events could be generated from a string using output from
  # {Accessibility::String#keyboard_events_for}.
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
  #   include Accessibility::String
  #   events = keyboard_events_for "Hello, world!\n"
  #   post events
  #
  # @param [Array<Array(Number,Boolean)>]
  # @param [AXUIElementRef]
  def post events
    events.each do |event|
      code = AXUIElementPostKeyboardEvent(self, 0, *event)
      handle_error code unless code.zero?
      sleep KEY_RATE
    end
    sleep 0.1 # in many cases, UI is not done updating right away
  end

  ##
  # @todo Make this runtime configurable.
  #
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
             when 'VERY_SLOW' then 0.9
             when 'SLOW'      then 0.09
             when nil         then 0.009
             else                  ENV['KEY_RATE'].to_f
             end


  # @group Element Hierarchy Entry Points

  ##
  # Find the top most element at a point on the screen that belongs to the
  # backing application. If the backing element is the system wide object
  # then the return is the top most element regardless of application.
  #
  # The coordinates should be specified using the flipped coordinate
  # system (origin is in the top-left, increasing downward and to the right
  # as if reading a book in English).
  #
  # If more than one element is at the position then the
  # z-order of the elements will be used to determine which is
  # "on top".
  #
  # @example
  #
  #   element_at [453, 200]  # table
  #
  # @param [#to_point]
  # @return [AXUIElementRef,nil]
  def element_at point
    ptr = Pointer.new ELEMENT
    case code = AXUIElementCopyElementAtPosition(self, *point.to_point, ptr)
    when 0                                  then ptr.value
    when KAXErrorNoValue                    then nil
    else handle_error code, point, nil, nil
    end
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
  # @todo Allow a `Method` object to be passed once MacRuby ticket #1463
  #       is fixed.
  #
  # Create and return a notification observer for the given object's
  # application. You should give a block to this method that accepts three
  # parameters: the observer, the notification sender, and the notification
  # name.
  #
  # Observer's belong to an application, so you can cache a particular
  # observer and use it for many different notification registrations.
  #
  # @example
  #
  #   observer do |obsrvr, sender, notif|
  #     # do stuff...
  #   end
  #
  # @yieldparam [AXObserverRef]
  # @yieldparam [AXUIElementRef]
  # @yieldparam [String]
  # @return [AXObserverRef]
  def observer
    raise ArgumentError, 'A callback is required' unless block_given?
    ptr      = Pointer.new OBSERVER
    callback = proc { |obsrvr, sender, notif, ctx| yield obsrvr, sender, notif }
    case code = AXObserverCreate(pid, callback, ptr)
    when 0 then ptr.value
    else handle_error code, callback
    end
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
  #   register observer, to_receive: KAXWindowCreatedNotification
  #
  # @param [AXObserverRef]
  # @param [String]
  # @return [Boolean]
  def register observer, to_receive: notif
    case code = AXObserverAddNotification(observer, self, notif, nil)
    when 0 then true
    else handle_error code, notif, observer, nil, nil
    end
  end

  ##
  # Unregister a notification that has been previously setup.
  #
  # @param [AXObserverRef]
  # @param [String]
  # @return [Boolean]
  def unregister observer, from_receiving: notif
    case code = AXObserverRemoveNotification(observer, self, notif)
    when 0 then true
    else handle_error code, notif, observer, nil, nil
    end
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
  # Get the process identifier (PID) of the application that the element
  # belongs to.
  #
  # @example
  #
  #   pid   # => 12345
  #
  # @return [Fixnum]
  def pid
    @pid ||= (
      ptr = Pointer.new :int
      case code = AXUIElementGetPid(self, ptr)
      when 0 then ptr.value
      else handle_error code
      end
      )
  end

  ##
  # Create a new reference to the system wide object. This is very useful when
  # working with the system wide object as caching the system wide reference
  # does not seem to work often.
  #
  # @example
  #
  #   system_wide  # => #<AXUIElementRefx00000000>
  #
  # @return [AXUIElementRef]
  def system_wide
    AXUIElementCreateSystemWide()
  end

  ##
  # Returns the application reference that the element belongs to.
  #
  # @return [AXUIElementRef]
  def application
    application_for pid
  end

  ##
  # Spin the run loop once. For the purpose of receiving notification
  # callbacks and other Cocoa methods that depend on a run loop.
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
  # Change the timeout value for the element. If you change the timeout
  # on the system wide object, it affets all timeouts.
  #
  # Setting the global timeout to `0` seconds will reset the timeout value
  # to the system default. Apple does not appear to have publicly documented
  # what the system default is though, so I can't tell you what that value
  # is.
  #
  # @param [Number]
  # @return [Number]
  def set_timeout_to seconds
    case code = AXUIElementSetMessagingTimeout(self, seconds)
    when 0 then seconds
    else handle_error code, seconds
    end
  end


  private

  # @group Error Handling

  # @param [Number]
  def handle_error code, *args
    klass, handler = AXERROR.fetch code, [RuntimeError, :handle_unknown]
    msg            = if handler == :handle_unknown
                       "You should never reach this line [#{code}]:#{inspect}"
                     else
                       self.send handler, *args
                     end
    raise klass, msg, caller(1)
  end

  def handle_failure *args
    "A system failure occurred with #{inspect}, stopping to be safe"
  end

  def handle_illegal_argument *args
    case args.size
    when 0
      "#{inspect} is not an AXUIElementRef"
    when 1
      "Either the element #{inspect} " +
        "or the attribute/action/callback #{args.first.inspect} " +
        "is not a legal argument"
    when 2
      "You can't get/set #{args.first.inspect} with/to " +
        "#{args[1].inspect} for #{inspect}"
    when 3
      "The point #{args.first.to_point.inspect} is not a valid point, " +
        "or #{inspect} is not an AXUIElementRef"
    when 4
      "Either the observer #{args[1].inspect}, " +
        "the element #{inspect}, or " +
        "the notification #{args.first.inspect} " +
        "is not a legitimate argument"
    end
  end

  def handle_invalid_element *args
    "#{inspect} is no longer a valid reference"
  end

  def handle_invalid_observer *args
    "#{args[1].inspect} is no longer a valid observer for " +
      "#{inspect} or was never valid"
  end

  # @param [AXUIElementRef]
  def handle_cannot_complete *args
    spin_run_loop
    app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    if app
      "An unspecified error occurred using #{inspect} with AXAPI" +
        ", maybe a timeout :("
    else
      "Application for pid=#{pid} is no longer running. Maybe it crashed?"
    end
  end

  def handle_attr_unsupported *args
    "#{inspect} does not have a #{args.first.inspect} attribute"
  end

  def handle_action_unsupported *args
    "#{inspect} does not have a #{args.first.inspect} action"
  end

  def handle_notif_unsupported *args
    "#{inspect} does not support the #{args.first.inspect} notification"
  end

  def handle_not_implemented *args
    "The program that owns #{inspect} does not work with AXAPI properly"
  end

  # @todo Does this really neeed to raise an exception? Seems
  #       like a warning would be sufficient.
  def handle_notif_registered *args
    "You have already registered to hear about #{args[0].inspect} " +
      "from #{inspect}"
  end

  def handle_notif_not_registered *args
    "You have not registered to hear about #{args[0].inspect} " +
      "from #{inspect}"
  end

  def handle_api_disabled *args
    'AXAPI has been disabled'
  end

  def handle_param_attr_unsupported *args
    "#{inspect} does not have a #{args[0].inspect} parameterized attribute"
  end

  def handle_not_enough_precision
    'AXAPI said there was not enough precision ¯\(°_o)/¯'
  end

  # @endgroup


  ##
  # @private
  #
  # `Pointer` type encoding for `CFArrayRef` objects.
  #
  # @return [String]
  ARRAY    = '^{__CFArray}'

  ##
  # @private
  #
  # `Pointer` type encoding for `AXUIElementRef` objects.
  #
  # @return [String]
  ELEMENT  = '^{__AXUIElement}'

  ##
  # @private
  #
  # `Pointer` type encoding for `AXObserverRef` objects.
  #
  # @return [String]
  OBSERVER = '^{__AXObserver}'

  ##
  # @private
  #
  # Mapping of `AXError` values to static information on how to handle
  # the error. Used by {handle_error}.
  #
  # @return [Hash{Number=>Array(Symbol,Range)}]
  AXERROR = {
    KAXErrorFailure                           => [RuntimeError,        :handle_failure               ],
    KAXErrorIllegalArgument                   => [ArgumentError,       :handle_illegal_argument      ],
    KAXErrorInvalidUIElement                  => [ArgumentError,       :handle_invalid_element       ],
    KAXErrorInvalidUIElementObserver          => [ArgumentError,       :handle_invalid_observer      ],
    KAXErrorCannotComplete                    => [RuntimeError,        :handle_cannot_complete       ],
    KAXErrorAttributeUnsupported              => [ArgumentError,       :handle_attr_unsupported      ],
    KAXErrorActionUnsupported                 => [ArgumentError,       :handle_action_unsupported    ],
    KAXErrorNotificationUnsupported           => [ArgumentError,       :handle_notif_unsupported     ],
    KAXErrorNotImplemented                    => [NotImplementedError, :handle_not_implemented       ],
    KAXErrorNotificationAlreadyRegistered     => [ArgumentError,       :handle_notif_registered      ],
    KAXErrorNotificationNotRegistered         => [RuntimeError,        :handle_notif_not_registered  ],
    KAXErrorAPIDisabled                       => [RuntimeError,        :handle_api_disabled          ],
    KAXErrorParameterizedAttributeUnsupported => [ArgumentError,       :handle_param_attr_unsupported],
    KAXErrorNotEnoughPrecision                => [RuntimeError,        :handle_not_enough_precision  ]
  }
end


##
# Mixin for the special `__NSCFType` class so that `#to_ruby` works properly.
module Accessibility::ValueUnwrapper
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
  # Unwrap an `AXValue` into the `Boxed` instance that it is supposed
  # to be. This will only work for the most common boxed types, you will
  # need to check the AXAPI documentation for an up to date list.
  #
  # @example
  #
  #   wrapped_point.to_ruby # => #<CGPoint x=44.3 y=99.0>
  #   wrapped_range.to_ruby # => #<CFRange begin=7 length=100>
  #   wrapped_thing.to_ruby # => wrapped_thing
  #
  # @return [Boxed]
  def to_ruby
    box_type = AXValueGetType(self)
    return self if box_type.zero?
    ptr = Pointer.new BOX_TYPES[box_type]
    AXValueGetValue(self, box_type, ptr)
    ptr.value.to_ruby
  end
end

# hack to find the proper class
klass = AXUIElementCreateSystemWide().class
klass.send :include, Accessibility::Core
klass.send :include, Accessibility::ValueUnwrapper


##
# AXElements extensions to the `Boxed` class. The `Boxed` class is
# simply an abstract base class for structs that MacRuby can use
# via bridge support.
class Boxed
  ##
  # Returns the number that AXAPI uses in order to know how to wrap
  # a struct.
  #
  # @return [Number]
  def self.ax_value
    raise NotImplementedError, "#{self.class} cannot be wraped"
  end

  ##
  # Create an `AXValueRef` from the `Boxed` instance. This will only
  # work if for the most common boxed types, you will need to check
  # the AXAPI documentation for an up to date list.
  #
  # @example
  #
  #   CGPointMake(12, 34).to_ax # => #<AXValueRef:0x455678e2>
  #   CGSizeMake(56, 78).to_ax  # => #<AXValueRef:0x555678e2>
  #
  # @return [AXValueRef]
  def to_ax
    klass = self.class
    ptr   = Pointer.new klass.type
    ptr.assign self
    AXValueCreate(klass.ax_value, ptr)
  end
end

# AXElements extensions for `CFRange`.
class << CFRange; def ax_value; KAXValueCFRangeType; end end
# AXElements extensions for `CGSize`.
class << CGSize;  def ax_value; KAXValueCGSizeType;  end end
# AXElements extensions for `CGRect`.
class << CGRect;  def ax_value; KAXValueCGRectType;  end end
# AXElements extensions for `CGPoint`.
class << CGPoint; def ax_value; KAXValueCGPointType; end end


# AXElements extensions for `NSObject`.
class NSObject
  def to_ax;   self end
  def to_ruby; self end
end

# AXElements extensions for `Range`.
class Range
  # @return [AXValueRef]
  def to_ax
    raise ArgumentError if last < 0 || first < 0
    length = if exclude_end?
               last - first
             else
               last - first + 1
             end
    CFRange.new(first, length).to_ax
  end
end

# AXElements extensions for `CFRange`.
class CFRange
  # @return [Range]
  def to_ruby
    Range.new location, (location + length - 1)
  end
end


unless Object.const_defined? :KAXIdentifierAttribute
  ##
  # Added for backwards compatability with Snow Leopard.
  # This attribute is standard with Lion and newer. AXElements depends
  # on it being defined.
  #
  # @return [String]
  KAXIdentifierAttribute = 'AXIdentifier'
end


# AXElements extensions to `NSArray`.
class NSArray
  # @return [CGPoint]
  def to_point; CGPoint.new(first, at(1)) end
  # @return [CGSize]
  def to_size;  CGSize.new(first, at(1))  end
  # @return [CGRect]
  def to_rect;  CGRectMake(*self[0..3])   end
end

# AXElements extensions for `CGPoint`.
class CGPoint
  # @return [CGPoint]
  def to_point; self end
end
