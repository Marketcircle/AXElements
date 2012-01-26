# -*- coding: utf-8 -*-

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
  def attribute attr
    attr == :focused? || attr == :focused ? active? : super
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
  # Overridden to handle the {Accessibility::Language#set_focus} case.
  def set attr, to: value
    if attr == :focused
      if value
        @app.unhide
        @app.activateWithOptions NSApplicationActivateIgnoringOtherApps
      else
        @app.hide
      end
    else
      super
    end
  end


  # @group Actions

  ##
  # @note This object becomes poisonous after the app terminates. If you
  #       try to use it again, you will crash MacRuby.
  #
  # Ask the application to terminate itself. Be careful how you use this.
  #
  # @return [Boolean]
  def perform name
    case name
    when :terminate, :hide, :unhide
      @app.send name
    else
      super
    end
  end

  ##
  # Send keyboard input to `self`, the control that currently has focus
  # will the control that receives the key presses.
  #
  # @return [nil]
  def type_string string
    keyboard_input string, to: @ref
  end

  # @endgroup


  # @todo Do we need to override #respond_to? and #methods for
  #       the :focused? case as well?

  ##
  # Override the base class to make sure the pid is included.
  def inspect
    (super).sub />$/, "#{pp_checkbox(:focused)} pid=#{self.pid}>"
  end

  ##
  # `nil` if there was nothing at that point.
  #
  # @return [AX::Element,nil]
  def element_at_point x, y
    element = element_at_point x, and: y, for: @ref
    process element
  end

end
