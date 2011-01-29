module AX

# All the non-default actions you can perform on an accessibility object,
# waiting to be mixed in by various objects.
module Traits

# All the different ways in which you can click on an object.
module Clicking
  # @return [boolean] true if successful, otherwise crash
  def left_click
    position = self.position
    size     = self.size
    position.x += (size.width / 2)
    position.y += (size.height / 2)
    mouse_event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, position, KCGMouseButtonLeft)
    CGEventPost(KCGHIDEventTap, mouse_event)
    mouse_event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseUp, position, KCGMouseButtonLeft)
    CGEventPost(KCGHIDEventTap, mouse_event)
    sleep 1
    true
  end
end

# In cases where you need to simulate keyboard input, such as entering
# passwords or triggering hotkeys, you will need to use this method.
#
# See the documentation page
# ![GeneratingEvents](/docs/file/docs/GeneratingEvents.markdown)
# on how to encode strings.
module Typing

  # Key codes are independant of the layout in the sense that they are
  # absolute key positions on the keyboard and that different layouts will
  # fuck things up differently.
  #
  # For testing we are going to have to standardize on one layout.
  #
  # A capital letter requires pressing caps lock or holding down the shift key.
  # You need to set keydown for the key and then !keydown or else it will act
  # like a key combination.
  #
  # @todo a small parser to generate the actual sequence of key presses to
  #  simulate. Most likely just going to extend built in string escape sequences.
  # @param [String] string the string you want typed on the screen
  # @return [boolean] always returns true
  def post_kb_event string
    app = AXUIElementCreateApplication(get_pid)

    string.each_char { |char|
      code = KEYCODE_MAP[char]
      AXUIElementPostKeyboardEvent(app, 0, code, true)
      AXUIElementPostKeyboardEvent(app, 0, code, false)
    }

    true
  end

  KEYCODE_MAP = {
    'a' => 0,
    'b' => 11,
    'c' => 8,
    'd' => 2,
    'e' => 14,
    'f' => 3,
    'g' => 5,
    'h' => 4,
    'i' => 34,
    'j' => 38,
    'k' => 40,
    'l' => 37,
    'm' => 46,
    'n' => 45,
    'o' => 31,
    'p' => 35,
    'q' => 12,
    'r' => 15,
    's' => 1,
    't' => 17,
    'u' => 32,
    'v' => 9,
    'w' => 13,
    'x' => 7,
    'y' => 16,
    'z' => 6,
    '1' => 18,
    '2' => 19,
    '3' => 20,
    '4' => 21,
    '5' => 23,
    '6' => 22,
    '7' => 26,
    '8' => 28,
    '9' => 25,
    '0' => 29,
    "\t"=> 48,
    ' ' => 49
  }
end


# You can find a list of built in notifications in Apple's [documentation](http://developer.apple.com/library/mac/#documentation/Accessibility/Reference/AccessibilityLowlevel/AXNotificationConstants_h/index.html).
module Notifications

  # @param [AXObserverRef] observer the observer being notified
  # @param [AXUIElementRef] element the element being referenced
  # @param [String] notif the notification name
  # @param [nil] refcon not really nil, but I have no idea what this
  #  is used for
  # @return
  def notif_method observer, element, notif, refcon
    @notif_proc.call observer, element, notif, refcon

    run_loop   = CFRunLoopGetCurrent()
    app_source = AXObserverGetRunLoopSource( observer )

    CFRunLoopRemoveSource( run_loop, app_source, KCFRunLoopDefaultMode )
    CFRunLoopStop( run_loop )
  end

  # @param [String] notif
  # @param [Float] timeout
  # @yield The block should include whatever you want to do when a
  #  notification is received.
  # @yieldparam [AXObserverRef] observer the observer being notified
  # @yieldparam [AXUIElementRef] element the element being referenced
  # @yieldparam [String] notif the notification name
  # @yieldparam [nil] refcon not really nil, but I have no idea what this
  #  is used for
  # @return [Boolean] true if the notification was received, otherwise false.
  #  There are actually four different return codes, three which are 'possible'
  #  to receive under the given conditions, but only two conditions which will
  #  occur under regular circumstances.
  def wait_for_notification notif, timeout = 10, &block
    @notif_proc  = block
    callback     = method :notif_method
    observer     = Application.application_for_pid( get_pid ).observer callback

    run_loop     = CFRunLoopGetCurrent()
    app_run_loop = AXObserverGetRunLoopSource( observer )

    log_error AXObserverAddNotification( observer, @ref, notif, nil )
    CFRunLoopAddSource( run_loop, app_run_loop, KCFRunLoopDefaultMode )

    # use RunInMode because it has timeout functionality
    CFRunLoopRunInMode( KCFRunLoopDefaultMode, timeout, false )
  end
end

end
end
