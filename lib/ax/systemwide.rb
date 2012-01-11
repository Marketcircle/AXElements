require 'singleton'
require 'ax/element'

##
# Represents the special `SystemWide` accessibility object.
class AX::SystemWide < AX::Element
  include Singleton

  ##
  # Overridden since there is only one way to get the element ref.
  def initialize
    ref = AXUIElementCreateSystemWide()
    super ref, attrs_for(ref)
  end

  ##
  # @note With the `SystemWide` class, using {#type_string} will send the
  #       events to which ever app has focus.
  #
  # Generate keyboard events by simulating keyboard input.
  def type_string string
    keyboard_input string, to: @ref
  end

  ##
  # Overridden to avoid a difficult to understand error message.
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
  # `nil` if there was nothing at that point.
  #
  # @return [AX::Element,nil]
  def element_at_point x, y
    element = element_at_point x, and: y, for: @ref
    self.class.process element
  end

end


##
# Singleton instance of the SystemWide element
#
# @return [AX::SystemWide]
AX::SYSTEM = AX::SystemWide.instance
