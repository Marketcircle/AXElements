module AX

# All the non-default actions you can perform on an accessibility object,
# waiting to be mixed in by various objects.
module Traits

# All the different ways in which you can click on an object.
module Click
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
module Type
  # @todo implement keyboard event posting method
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
  # @param [[Fixnum, boolean]] *keys a pair with the keycode and the state
  # @return [boolean] always returns true
  def post_kb_event *keys
    pid = Pointer.new 'i'
    AXUIElementGetPid(@ref, pid)
    app = AXUIElementCreateApplication(pid[0])

    keys.each { |pair|
      AXUIElementPostKeyboardEvent(app, pair[0], 1, pair[1])
    }

    true
  end
end

end
end
