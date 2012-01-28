require 'ax/element'

##
# Some additional constructors and conveniences for Application objects.
#
# As this class has evolved, it has gathered some functionality from
# the `NSRunningApplication` class.
class AX::Application < AX::Element

  ##
  # Overridden so that we can also cache the `NSRunningApplication`
  # instance for this object.
  def initialize ref, attrs
    super
    @app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
  end


  # @group Attributes

  ##
  # Overridden to handle the {Accessibility::Language#set_focus} case.
  #
  # (see AX::Element#attribute)
  def attribute attr
    case attr
    when :focused?, :focused then active?
    when :hidden?,  :hidden  then hidden?
    else
      super
    end
  end

  ##
  # Ask the app whether or not it is the active app. This is equivalent
  # to the dynamic #focused? method, but might make more sense to use
  # in some cases.
  def active?
    NSRunLoop.currentRunLoop.runUntilDate Time.now
    @app.active?
  end
  alias_method :focused,  :active?
  alias_method :focused?, :active?

  ##
  # Ask the app whether or not it is hidden.
  def hidden?
    NSRunLoop.currentRunLoop.runUntilDate Time.now
    @app.hidden?
  end

  ##
  # Overridden to handle the {Accessibility::Language#set_focus} case.
  #
  # (see AX::Element#set:to:)
  def set attr, to: value
    case attr
    when :focused, :active
      if value
        perform :unhide
        @app.activateWithOptions NSApplicationActivateIgnoringOtherApps
      else
        perform :hide
      end
    when :hidden then
      perform(value ? :hide : :unhide)
    else
      super
    end
  end


  # @group Actions

  ##
  # Overridden to provide extra actions (e.g. `hide`, `terminate`).
  #
  # (see AX::Element#perform)
  #
  # @return [Boolean]
  def perform name
    case name
    when :terminate, :hide, :unhide
      @app.send(name).tap { |_| sleep 0.15 }
    else
      super
    end
  end

  ##
  # Send keyboard input to `self`, the control in the app that currently
  # has focus will receive the key presses.
  #
  # For details on how to format the string, check out the
  # {file:docs/KeyboardEvents.markdown Keyboard tutorial}.
  #
  # @return [nil]
  def type_string string
    keyboard_input string, to: @ref
  end

  # @endgroup


  ##
  # Override the base class to make sure the pid is included.
  def inspect
    (super).sub />$/, "#{pp_checkbox(:focused)} pid=#{self.pid}>"
  end

  ##
  # Find the element in `self` that is present at point given.
  #
  # `nil` will be returned if there was nothing at that point.
  #
  # @return [AX::Element,nil]
  def element_at_point x, y
    element = element_at_point x, and: y, for: @ref
    process element
  end

end
