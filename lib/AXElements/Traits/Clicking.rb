module AX

##
# All the non-default actions you can perform on an accessibility object
# which are not tightly coupled and can be mixed in elsewhere.
module Traits

  ##
  # All the different ways in which you can click on an object.
  # See [Mouse Events](../../file/MouseEvents.markdown) for more
  # detailed documentation on using methods from this module.
  module Clicking

    # @return [Boolean] true if successful, otherwise crash
    def left_click
      position    = self.position
      size        = self.size
      position.x += size.width  / 2
      position.y += size.height / 2
      mouse_event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, position, KCGMouseButtonLeft)
      CGEventPost(KCGHIDEventTap, mouse_event)
      mouse_event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseUp, position, KCGMouseButtonLeft)
      CGEventPost(KCGHIDEventTap, mouse_event)
      sleep 1
      true
    end

    # click and hold
    # click
    # double click
    # drag
    # all of the above have to be doable with left, right, and middle buttons
    # scroll

    # one idea is to compose mouse events, everything starts with creating a generic event source
    # followed by the desired event, followed by posting the event

    # CGEventCReaeteScrollWheelEvent for scrolling
    # CGEventCreateMouseEvent for clicking
    # CGEventGetUnflippedLocation for getting the carbon co-ordinates
    # CGEventSetLocation @todo find out if this actually moves the mouse

  end

end
end
