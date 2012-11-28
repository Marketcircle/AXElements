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

  class << self
    ##
    # Asynchronously launch an application with given the bundle identifier
    #
    # @param bundle [String] bundle identifier for the app
    # @return [Boolean]
    def launch bundle
      NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier bundle,
                                                       options: NSWorkspaceLaunchAsync,
                                additionalEventParamDescriptor: nil,
                                              launchIdentifier: nil
    end
  end

  ##
  # Standard way of creating a new application object
  #
  # You can initialize an application object with either the process
  # identifier (pid) of the application, the name of the application,
  # an `NSRunningApplication` instance for the application, or an
  # accessibility (`AXUIElementRef`) token.
  #
  # Given a PID, we try to lookup the application and wrap it.
  #
  # Given an `NSRunningApplication` instance, we simply wrap it.
  #
  # Given a string we do some complicated magic to try and figure out if
  # the string is a bundle identifier or the localized name of the
  # application. Given a bundle identifier we try to launch the app if
  # it is not already running, given a localized name we search the running
  # applications for the app. We wrap what we get back if we get anything
  # back.
  #
  # Note however, given a bundle identifier to launch the application our
  # implementation is a bit of a hack; I've tried to register for
  # notifications, launch synchronously, etc., but there is always a problem
  # with accessibility not being ready right away, so we will poll the app
  # to see when it is ready with a timeout of ~10 seconds.
  #
  # If this method fails to find an app then an exception will be raised.
  #
  # @example
  #
  #   AX::Application.new 'com.apple.mail'
  #   AX::Application.new 'Mail'
  #   AX::Application.new 43567
  #
  # @param arg [Number,String,NSRunningApplication]
  def initialize arg
    case arg
    when Fixnum
      super Accessibility::Element.application_for arg
      @app = NSRunningApplication.runningApplicationWithProcessIdentifier arg
    when String
      until @app
        @app =
         (
          app = NSRunningApplication.runningApplicationsWithBundleIdentifier arg
          app.first

         ) || (
           spin_run_loop
           NSWorkspace.sharedWorkspace.runningApplications.find { |app|
             app.localizedName == arg
           }

         ) || (
           count ||= 0
           if AX::Application.launch arg
             sleep 1
             count += 1
             raise "#{arg} failed to launch in time" if count == 10
           else
             raise "#{arg} is not a registered bundle identifier for the system"
           end
        )
      end
      super Accessibility::Element.application_for @app.processIdentifier
    when NSRunningApplication
      super Accessibility::Element.application_for arg.processIdentifier
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

  ##
  # @note This is often async and may return before the action is completed
  #
  # Ask the app to quit
  #
  # @return [Boolean]
  def terminate
    perform :terminate
  end

  ##
  # @note This is often async and may return before the action is completed
  #
  # Force the app to quit
  #
  # @return [Boolean]
  def terminate!
    perform :force_terminate
  end

  ##
  # @note This is often async and may return before the action is completed
  #
  # Ask the app to hide itself
  #
  # @return [Boolean]
  def hide
    perform :hide
  end

  ##
  # @note This is often async and may return before the action is completed
  #
  # As the app to unhide itself and bring to front
  #
  # @return [Boolean]
  def unhide
    perform :unhide
  end

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
    @ref.element_at(point).to_ruby
  end


  private

  # @return [nil]
  def spin_run_loop
    NSRunLoop.currentRunLoop.runUntilDate Time.now
  end

  # @return [NSBundle]
  def bundle
    @bundle ||= NSBundle.bundleWithURL @app.bundleURL
  end

end
