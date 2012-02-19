require 'ax/element'
require 'accessibility/string_parser'

##
# Represents the special `SystemWide` accessibility object.
#
# Previously, this object was a singleton, but that apparently causes
# problems with the AXAPIs. So you should always create a new instance
# of the system wide object when you need to use it (even though they
# are all the same thing).
class AX::SystemWide < AX::Element
  include Accessibility::StringParser

  ##
  # Overridden since there is only one way to get the element ref.
  def initialize
    ref = system_wide
    super ref, attrs_for(ref)
  end

  ##
  # @note With the `SystemWide` class, using {#type_string} will send the
  #       events to which ever app has focus.
  #
  # Generate keyboard events by simulating keyboard input.
  #
  # See the {file:docs/KeyboardEvents.markdown Keyboard} documentation for
  # more information on how to format strings.
  #
  # @return [Boolean]
  def type_string string
    events = create_events_for string
    post events, to: @ref
    true
  end

  def keydown modifier
    post [[ESCAPES[modifier], true]], to: @ref
    true
  end

  def keyup modifier
    post [[ESCAPES[modifier], false]], to: @ref
    true
  end

  ##
  # The system wide object cannot be used to perform searches. This method
  # is just an override to avoid a difficult to understand error messages.
  def search *args
    raise NoMethodError, 'AX::SystemWide cannot search'
  end

  ##
  # Raises an `NoMethodError` instead of (possibly) silently failing to
  # register for a notification.
  #
  # @raise [NoMethodError]
  def on_notification *args
    raise NoMethodError, 'AX::SystemWide cannot register for notifications'
  end

  ##
  # Find the element in at the given point for the topmost appilcation
  # window.
  #
  # `nil` will be returned if there was nothing at that point.
  #
  # @return [AX::Element,nil]
  def element_at_point x, y
    element = element_at_point x, and: y, for: @ref
    process element
  end

end
