require 'singleton'

module AX

##
# Represents the special SystemWide accessibility object.
class SystemWide < AX::Element
  include Singleton

  def initialize
    super AXUIElementCreateSystemWide()
  end

  ##
  # @note With the SystemWide class, using {#type_string} will send the
  #       events to which ever app has focus.
  #
  # Generate keyboard events by simulating keyboard input.
  def type_string string
    AX.keyboard_action( @ref, string )
  end

  ##
  # Overridden to avoid a difficult to understand error message.
  def search *args
    problem 'AX::SystemWide cannot search'
  end

  ##
  # Raises an `ArgumentError` instead of (possibly) silently failing to
  # register for a notification.
  def on_notification *args
    problem 'AX::SystemWide cannot register for notifications'
  end


  private

  def problem string
    raise ArgumentError, string
  end

end
end
