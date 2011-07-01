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
  # Overridden to handle the {Kernel#set_focus} case.
  def set_attribute attr, value
    if attr == :focused
      @app.activateWithOptions NSApplicationActivateAllWindows
    else
      super
    end
  end

  ##
  # Overridden to hand the {Kernel#set_focus} case.
  def attribute attr
    attr == :focused? || attr == :focused ? active? : super
  end

  # @todo Do we need to override #respond_to? and #methods for
  #       the :focused? case as well?

  ##
  # Ask the app whether or not it is the active app. This is equivalent
  # to the dynamic #focused? method, but might make more sense to use
  # in some cases.
  def active?
    app.active
  end

  ##
  # Override the base class to make sure the pid is included.
  def inspect
    (super).sub />$/, " @pid=#{self.pid}>"
  end

  ##
  # @note Key presses are async...or are they?
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
