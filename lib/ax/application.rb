require 'ax/element'
require 'accessibility/string'

##
# The accessibility object representing the running application. This
# class contains some additional constructors and conveniences for
# Application objects.
#
# As this class has evolved, it has gathered some functionality from
# the `NSRunningApplication` and `NSBundle` classes.
class AX::Application < AX::Element
  include Accessibility::String

  ##
  # You can initialize an application object with either the process
  # identifier (pid) of the application, the name of the application,
  # an `NSRunningApplication` instance for the application, or an
  # accessibility (`AXUIElementRef`) token.
  #
  # @param arg [Number,String,NSRunningApplication]
  def initialize arg
    case arg
    when Fixnum
      super SYSTEMWIDE.application_for arg
      @app = NSRunningApplication.runningApplicationWithProcessIdentifier arg
    when String
      @app =
        NSRunningApplication.runningApplicationsWithBundleIdentifier(arg).first ||
        (
          SYSTEMWIDE.spin_run_loop
          NSWorkspace.sharedWorkspace.runningApplications.find { |app|
            app.localizedName == arg
          }
        )
      super SYSTEMWIDE.application_for @app.processIdentifier
    when NSRunningApplication
      super SYSTEMWIDE.application_for arg.processIdentifier
      @app = arg
    else
      super arg # assume it is an AXUIElementRef
      @app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    end
  end


  # @group Attributes

  # (see AX::Element#attribute)
  def attribute attr
    case attr
    when :focused?, :focused then active?
    when :hidden?,  :hidden  then hidden?
    else super
    end
  end

  # (see AX::Element#writable?)
  def writable? attr
    case attr
    when :focused?, :focused, :hidden?, :hidden then true
    else super
    end
  end

  ##
  # Ask the app whether or not it is the active app. This is equivalent
  # to the dynamic `#focused?` method, but might make more sense to use
  # in some cases.
  def active?
    @ref.spin_run_loop
    @app.active?
  end
  alias_method :focused,  :active?
  alias_method :focused?, :active?

  ##
  # Ask the app whether or not it is hidden.
  def hidden?
    @ref.spin_run_loop
    @app.hidden?
  end

  ##
  # Ask the app whether or not it is still running.
  def terminated?
    @ref.spin_run_loop
    @app.terminated?
  end

  # (see AX::Element#set)
  def set attr, value
    case attr
    when :focused
      perform(value ? :unhide : :hide)
    when :active, :hidden
      perform(value ? :hide : :unhide)
    else
      super
    end
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

  ##
  # Return the `Info.plist` data for the application. This is a plist
  # file that all bundles in OS X must contain.
  #
  # Many bits of metadata are stored in the plist, check the
  # [reference](https://developer.apple.com/library/mac/#documentation/MacOSX/Conceptual/BPRuntimeConfig/Articles/ConfigFiles.html)
  # for more details.
  #
  # @return [Hash]
  def info_plist
    bundle.infoDictionary
  end

  ##
  # Get the version string for the application.
  #
  # @example
  #
  #   AX::Application.new("Safari").version    # => "5.2"
  #   AX::Application.new("Terminal").version  # => "2.2.2"
  #   AX::Application.new("Daylite").version   # => "3.15 (build 3664)"
  #
  # @return [String]
  def version
    bundle.objectForInfoDictionaryKey 'CFBundleShortVersionString'
  end


  # @group Actions


  # (see AX::Element#perform)
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
  # Send keyboard input to the receiver, the control in the app that
  # currently has focus will receive the key presses.
  #
  # For details on how to format the string, check out the
  # [Keyboarding documentation](http://github.com/Marketcircle/AXElements/wiki/Keyboarding).
  #
  # @param string [String]
  # @return [Boolean]
  def type string
    @ref.post keyboard_events_for string
    true
  end
  alias_method :type_string, :type

  ##
  # Press the given modifier key and hold it down while yielding to
  # the given block.
  #
  # @example
  #
  #   hold_key "\\CONTROL" do
  #     drag_mouse_to point
  #   end
  #
  # @param key [String]
  # @return [Number,nil]
  def hold_modifier key
    code = EventGenerator::CUSTOM[key]
    raise ArgumentError, "Invalid modifier `#{key}' given" unless code
    @ref.post [[code, true]]
    yield
  ensure
    @ref.post [[code,false]] if code
    code
  end

  ##
  # Navigate the menu bar menus for the receiver and select the menu
  # item at the end of the given path. This method will open each menu
  # in the path.
  #
  # @example
  #
  #   safari.select_menu_item 'Edit', 'Find', /Google/
  #
  # @param path [String,Regexp]
  # @return [AX::MenuItem]
  def select_menu_item *path
    target = navigate_menu *path
    target.perform :press
    target
  end

  ##
  # Navigate the menu bar menus for the receiver. This method will not
  # select the last item, but it will open each menu along the path.
  #
  # You may also be interested in {#select_menu_item}.
  #
  # @param path [String,Regexp]
  # @return [AX::MenuItem]
  def navigate_menu *path
    perform :unhide # can't navigate menus unless the app is up front
    bar_item = item = self.menu_bar.menu_bar_item(title: path.shift)
    path.each do |part|
      item.perform :press
      next_item = item.menu_item(title: part)
      item = next_item
    end
    item
  ensure
    # got to the end
    bar_item.perform :cancel unless item.title == path.last
  end

  ##
  # Show the "About" window for the app. Returns the window that is
  # opened.
  #
  # @return [AX::Window]
  def show_about_window
    windows = self.children.select { |x| x.kind_of? AX::Window }
    select_menu_item self.title, /^About /
    wait_for(:window, parent: self) { |window| !windows.include?(window) }
  end

  ##
  # @note This method assumes that the app has setup the standard
  #       CMD+, hotkey to open the pref window
  #
  # Try to open the preferences for the app. Returns the window that
  # is opened.
  #
  # @return [AX::Window]
  def show_preferences_window
    windows = self.children.select { |x| x.kind_of? AX::Window }
    type "\\COMMAND+,"
    wait_for(:window, parent: self) { |window| !windows.include?(window) }
  end

  # @endgroup


  ##
  # Override the base class to make sure the pid is included.
  def inspect
    super.sub! />$/, "#{pp_checkbox(:focused)} pid=#{pid}>"
  end

  ##
  # Find the element in the receiver that is at point given.
  #
  # `nil` will be returned if there was nothing at that point.
  #
  # @param point [#to_point]
  # @return [AX::Element,nil]
  def element_at point
    process @ref.element_at point
  end


  private

  # @return [NSBundle]
  def bundle
    @bundle ||= NSBundle.bundleWithURL @app.bundleURL
  end

  # @private
  # @return [AXUIElementRef]
  SYSTEMWIDE = AXUIElementCreateSystemWide()

end
