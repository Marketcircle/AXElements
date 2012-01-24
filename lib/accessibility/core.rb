require 'accessibility/core/notifications'
require 'accessibility/core/string_parser'

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
# Except for the notification related APIs, everything here is stateless
# and therefore thread safe.
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
  #     # => ["AXRole", "AXRoleDescription", "AXFocusedUIElement", "AXFocusedApplication"]
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
  #   attr KAXSizeAttribute,    for: window  # => #<AXValueRefx00000000>
  #   attr KAXParentAttribute,  for: window  # => #<AXUIElementRefx00000000>
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
    # @todo Handle error codes?
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
  #   keyboard_input "www.macruby.org\r", to: safari_ref,
  #
  # @param [String] string keyboard events as a string
  # @param [AXUIElementRef] app must be an application or
  #   the system-wide accessibility object
  # @return [nil]
  def keyboard_input string, to: app
    parser = Accessibility::Core::StringParser.new
    events = parser.parse string
    post events, to: app
    nil
  end

  ##
  # Post the list of given keyboard events to the given application,
  # or the system-wide accessibility object.
  #
  # Events should be generated using {Accessibility::Core::StringParser},
  # and this method is normally only called by {keyboard_input:to:}.
  #
  # @param [AXUIElementRef] app
  # @param [Array<Array(Number,Boolean)>]
  def post events, to: app
    # This is just a magic number from trial and error. I tried both the repeat interval (NXKeyRepeatInterval) and threshold (NXKeyRepeatThreshold) but both were way too big.
    key_rate = 0.009

    events.each do |event|
      code = AXUIElementPostKeyboardEvent(app, 0, *event)
      handle_error code, app unless code.zero?
      sleep key_rate
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
  #   range = CFRange.new(1, 10).to_axvalue
  #   param_attr KAXStringForRangeParameterizedAttribute, for_param: range, for: text_field_ref
  #     # => "ello, worl"
  #
  # @param [String] attr an attribute constant
  # @param [Object] param
  # @param [AXUIElementRef]
  def param_attr attr, for_param: param, for: element
    ptr  = Pointer.new :id
    code = AXUIElementCopyParameterizedAttributeValue(element, attr, param, ptr)
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
    NSRunLoop.currentRunLoop.runUntilDate Time.now
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

  # @endgroup


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

  # @param [Number]
  def handle_error code, *args
    case code
    when KAXErrorIllegalArgument
      msg = case args.size
            when 1
              "'#{CFCopyDescription(args.first)}' is not an AXUIElementRef"
            when 2
              "Either the element '#{CFCopyDescription(args.first)}' " +
                "or the attr/action '#{args.second}' is not a legal argument"
            when 3
              "You can't set '#{args.second}' to '#{CFCopyDescription(args.third)}' " +
                "for '#{CFCopyDescription(args.first)}'"
            when 4
              "The point [#{args.second}, #{args.third}] is not a valid point, or " +
                "'#{CFCopyDescription(args.first)}' is not an AXUIElementRef"
            end
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement
      msg = "'#{CFCopyDescription(args.first)}' is no longer a valid token"
      raise RuntimeError, msg
    when KAXErrorAttributeUnsupported
      msg = "'#{CFCopyDescription(args.first)}' doesn't have '#{args.second}'"
      raise ArgumentError, msg
    when KAXErrorActionUnsupported
      msg = "'#{CFCopyDescription(args.first)}' doesn't have '#{args.second}'"
      raise ArgumentError, msg
    when KAXErrorParameterizedAttributeUnsupported then
      msg = "'#{CFCopyDescription(args.first)}' does not have parameterized attributes"
      raise ArgumentError, msg
    when KAXErrorFailure
      msg = 'Some kind of system failure occurred, stopping to be safe'
      raise RuntimeError, msg
    when KAXErrorCannotComplete
      msg = 'Some unspecified error occurred with AXAPI. Sorry. :('
      raise RuntimeError, msg
    when KAXErrorNotImplemented
      msg  = "The program that owns '#{CFCopyDescription(args.first)}' "
      msg << 'does not work with AXAPI properly'
      raise NotImplementedError, msg
    else
      raise "You should never reach this line! [#{code.inspect}]"
    end
  end

end
