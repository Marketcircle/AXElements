##
# Some additional constructors and conveniences for Application objects.
#
# As this class has evolved, it has gathered some functionality from
# the NSRunningApplication class.
class AX::Application < AX::Element

  # @return [NSRunningApplication] the NSRunningApplication instance for
  #   application this object represents
  attr_reader :app

  ##
  # Overridden so that we can also cache the NSRunningApplication
  # instance for this object.
  def initialize ref
    super
    @app = NSRunningApplication.runningApplicationWithProcessIdentifier(pid)
  end

  ##
  # Overriden to handle the {Kernel#set_focus} case.
  def set_attribute attr, value
    if attr == :focused and !@app.active
      @app.activateWithOptions NSApplicationActivateAllWindows
    else
      super
    end
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
  # @note That this object becomes poisonous after the app terminates.
  #       That is to say, if you try to use it again, you will crash
  #       MacRuby.
  #
  # Ask the application to terminate itself.
  #
  # @return [Boolean]
  def terminate
    @app.terminate
  end

end
