require 'ax/element'
require 'accessibility/string_parser'

##
# Some additional constructors and conveniences for Application objects.
#
# As this class has evolved, it has gathered some functionality from
# the `NSRunningApplication` class.
class AX::Application < AX::Element
  include Accessibility::String

  ##
  # Overridden so that we can also cache the `NSRunningApplication`
  # instance for this object.
  def init ref, attrs
    super
    @app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
  end

  ##
  # Overridden so that we can also cache the `NSRunningApplication`
  # instance for this object.
  #
  # You can initialize an application object with either the process
  # identifier (pid) of the application, the name of the application,
  # an `NSRunningApplication` instance for the application, or an
  # accessibility (`AXUIElementRef`) token.
  def initialize arg
    case arg
    when Fixnum
      super application_for arg
      @app = NSRunningApplication.runningApplicationWithProcessIdentifier arg
    when String
      spin_run_loop
      @app = NSWorkspace.sharedWorkspace.runningApplications
        .find { |app| app.localizedName == arg }
      super application_for @app.processIdentifier
    when NSRunningApplication
      super application_for arg.processIdentifier
      @app = arg
    else
      super arg # assume it is an AXUIElementRef
      @app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    end
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
    spin_run_loop
    @app.active?
  end
  alias_method :focused,  :active?
  alias_method :focused?, :active?

  ##
  # Ask the app whether or not it is hidden.
  def hidden?
    spin_run_loop
    @app.hidden?
  end

  ##
  # Ask the app whether or not it is still running.
  def terminated?
    spin_run_loop
    @app.terminated?
  end

  ##
  # Overridden to handle the {Accessibility::Language#set_focus} case.
  #
  # (see AX::Element#set:to:)
  def set attr, to: value
    case attr
    when :focused
      perform(value ? :unhide : :hide)
    when :active, :hidden
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
    when :terminate
      return true if terminated?
      @app.terminate; sleep 0.2; terminated?
    when :force_terminate
      return true if terminated?
      @app.forceTerminate; sleep 0.2; terminated?
    when :hide
      return true if hidden?
      @app.hide; sleep 0.2; hidden?
    when :unhide
      return true if active?
      @app.activateWithOptions(NSApplicationActivateIgnoringOtherApps)
      sleep 0.2; active?
    else
      super
    end
  end

  ##
  # Send keyboard input to `self`, the control in the app that currently
  # has focus will receive the key presses.
  #
  # For details on how to format the string, check out the
  # {file:docs/KeyboardEvents.markdown Keyboard} documentation.
  #
  # @return [Boolean]
  def type_string string
    events = events_for string
    post events, to: @ref
    true
  end

  def keydown key
    post [[CUSTOM[key], true]], to: @ref
    true
  end

  def keyup key
    post [[CUSTOM[key], false]], to: @ref
  end

  def select_menu *path
    press navigate_menu(*path)
  end

  def navigate_menu *path
    perform :unhide # can't navigate menus unless the app is up front
    current = attribute(:menu_bar).search(:menu_bar_item, title: path.shift)
    path.each do |part|
      press current
      next_item = current.search(:menu_item, title: part)
      if next_item.blank?
        raise Accessibility::SearchFailure.new(current, :menu_item, title: part)
      else
        current = next_item
      end
    end
    current
  end

  # @endgroup


  ##
  # @todo Include bundle identifier?
  #
  # Override the base class to make sure the pid is included.
  def inspect
    (super).sub! />$/, "#{pp_checkbox(:focused)} pid=#{pid}>"
  end

  ##
  # Find the element in `self` that is present at point given.
  #
  # `nil` will be returned if there was nothing at that point.
  #
  # @return [AX::Element,nil]
  def element_at_point x, y
    process element_at(CGPointMake(x, y), for: @ref)
  end

  ##
  # Get the bundle identifier for the application.
  #
  # @example
  #
  #   safari.bundle_identifier 'com.apple.safari'
  #   daylite.bundle_identifier 'com.marketcircle.Daylite'
  #
  # @return [String]
  def bundle_identifier
    @app.bundleIdentifier
  end

end
