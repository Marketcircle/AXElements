module AX

module Traits

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

  end

end
end
