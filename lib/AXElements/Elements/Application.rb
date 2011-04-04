module AX

##
# Some additional constructors and conveniences for Application objects.
class Application < AX::Element

  class << self

    ##
    # @todo Find a way for this method to work without sleeping;
    #       consider looping begin/rescue/end until AX starts up
    # @todo Search NSWorkspace.sharedWorkspace.runningApplications ?
    # @todo add another app launching method using app names
    #
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
    # @param [Float] timeout how long to wait between polling
    # @return [AX::Application]
    def self.application_with_bundle_identifier bundle, sleep_time = 2
      while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
        launch_application bundle
        sleep sleep_time
      end
      AX.application_for_pid( apps.first.processIdentifier )
    end


    private

    ##
    # This method uses asynchronous method calls to launch applications.
    #
    # @param [String] bundle the bundle identifier for the app
    # @return [Boolean]
    def self.launch_application bundle
      AX.log.info "Launching app with bundleID '#{bundle}'"
      NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier bundle,
                                                        options:NSWorkspaceLaunchAsync,
                                 additionalEventParamDescriptor:nil,
                                               launchIdentifier:nil
    end
  end


  ##
  # @todo This method needs a fall back procedure if the app does not
  #       have a dock icon
  #
  # The inherited {Element#set_focus} will not work for applications,
  # so we will just get focus by "clicking" the dock icon for the app.
  #
  # @return [Boolean] true if successful, otherwise unpredictable
  def set_focus
    AX::DOCK.application_dock_item(title: title).perform_action(:press)
  end

  ##
  # A macro for showing the About window for an app.
  def show_about_window
    self.set_focus
    self.menu_bar_item(title:(self.title)).press
    self.menu_bar.menu_item(title: "About #{self.title}").press
  end

  ##
  # Overriden to handle the {#set_focus} case.
  def set_attribute attr, value
    set_focus if attr == :focused
    super
  end

  ##
  # Create and return a notification observer for the object's application.
  # This method is almost never directly called, it is instead called by
  # {Traits::Notifications#wait_for_notification}.
  #
  # @param [Proc] callback
  # @return [AXObserverRef]
  def observer callback
    observer = Pointer.new '^{__AXObserver}'
    code = AXObserverCreate( pid, callback, observer )
    AX.log_ax_call( @ref, code )
    observer[0]
  end

  ##
  # Override the base class to make sure the pid is included.
  def inspect
    (super).sub />$/, " @pid=#{self.pid}>"
  end

  ##
  # @todo look at CGEventKeyboardSetUnicodeString for posting events
  #       without needing the keycodes
  # @todo look at UCKeyTranslate for working with different keyboard
  #       layouts
  # @todo a small parser to generate the actual sequence of key presses to
  #       simulate. Most likely just going to extend built in string escape
  #       sequences if possible
  # @note This method only handles lower case letters, spaces, tabs, and
  #       the escape key right now.
  #
  # In cases where you need (or want) to simulate keyboard input, such as
  # triggering hotkeys, you will need to use this method.
  #
  # See the documentation page [KeyboardEvents](file/KeyboardEvents.markdown)
  # on how to encode strings, as well as other details on using methods
  # from this module.
  #
  # @param [String] string the string you want typed on the screen
  # @return [Boolean] true unless something goes horribly wrong
  def post_kb_event string
    string.each_char { |char|
      code = KEYCODE_MAP[char]
      AXUIElementPostKeyboardEvent(@ref, 0, code, true)
      AXUIElementPostKeyboardEvent(@ref, 0, code, false)
    }
    true
  end

  KEYCODE_MAP = {
    # Letters
    'a' => 0, 'b' => 11, 'c' => 8, 'd' => 2, 'e' => 14, 'f' => 3, 'g' => 5,
    'h' => 4, 'i' => 34, 'j' => 38, 'k' => 40, 'l' => 37, 'm' => 46,
    'n' => 45, 'o' => 31, 'p' => 35, 'q' => 12, 'r' => 15, 's' => 1,
    't' => 17, 'u' => 32, 'v' => 9, 'w' => 13, 'x' => 7, 'y' => 16, 'z' => 6,
    # Numbers
    '1' => 18, '2' => 19, '3' => 20, '4' => 21, '5' => 23, '6' => 22,
    '7' => 26, '8' => 28, '9' => 25, '0' => 29,
    # Misc.
    "\t"=> 48, ' ' => 49, "\e"=> 53
  }

end
end
