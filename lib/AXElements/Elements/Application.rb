##
# Some additional constructors and conveniences for Application objects.
class AX::Application < AX::Element

  ##
  # Overriden to handle the {Kernel#set_focus} case.
  def set_attribute attr, value
    return set_focus if attr == :focused && value == true
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

  ##
  # Ask the application to terminate itself.
  #
  # @return [Boolean]
  def terminate
    NSRunningApplication.runningApplicationWithProcessIdentifier(pid).terminate
  end


  private

  ##
  # @todo This method needs a fall back procedure if the app does not
  #       have a dock icon (e.g. the dock doesn't have a dock icon).
  #       We could have alternative methods for setting focus, such as
  #       using CMD+TAB or Expose
  def set_focus
    AX::DOCK.application_dock_item(title: self.title).perform_action(:press)
  end

end
