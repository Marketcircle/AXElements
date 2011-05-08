module AX

##
# Some additional constructors and conveniences for Application objects.
class Application < AX::Element

  ##
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
  # @param [Float] sleep_time how long to wait between polling
  # @return [AX::Application]
  def self.application_with_bundle_identifier bundle, sleep_time = 2
    Accessibility.application_with_bundle_identifier(bundle, sleep_time)
  end

  ##
  # Overriden to handle the {Kernel#set_focus} case.
  def set_attribute attr, value
    return set_focus if attr == :focused
    return super
  end

  ##
  # Override the base class to make sure the pid is included.
  def inspect
    (super).sub />$/, " @pid=#{self.pid}>"
  end

  ##
  # @note Key presses are async
  #
  # Send keyboard input to `self`, the control that currently has focus
  # will the control that receives the key presses.
  def type_string string
    AX.keyboard_action( @ref, string )
  end


  private

  ##
  # @todo This method needs a fall back procedure if the app does not
  #       have a dock icon (i.e. the dock doesn't have a dock icon)
  def set_focus
    AX::DOCK.application_dock_item(title: title).perform_action(:press)
  end

end
end
