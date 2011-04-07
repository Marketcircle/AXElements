framework 'Cocoa'
require   'AXElements/CoreExtensions'

##
# @todo Add inertial scrolling abilities
# @todo Bezier paths for movements
# @todo Random background movements
# @todo Less discrimination against left handed people
# @todo A more intelligent default duration
module Mouse
class << self

  ##
  # Move the mouse from wherever it is to any given point.
  #
  # @param [CGPoint] point
  # @param [Float] duration animation duration, in seconds
  def move_to point, duration = 0.2
    move( current_position, point, duration )
  end

  ##
  # Click and drag from wherever it is to any given point.
  #
  # @param [CGPoint] point
  # @param [Float] duration animation duration, in seconds
  def drag_to point, duration = 0.2
    left_click_down( current_position )
    left_drag(       current_position, point, duration )
    left_click_up(   point )
  end

  ##
  # @todo Need to double check to see if I introduce any inaccuracies.
  #
  # Scrolling too much or too little in a period of time will cause the
  # animation to look weird, possibly causing the app to mess things up.
  #
  # @param [Fixnum] amount number of pixels/lines to scroll; positive
  #                        to scroll up or negative to scroll down
  # @param [Float] duration animation duration, in seconds
  # @param [Fixnum] units :line scrolls by line, :pixel scrolls by pixel
  def scroll amount, duration = 0.2, units = :line
    units   = unit_constant_for units
    steps   = (FPS * duration).floor
    current = 0.0
    steps.times do |step|
      done     = (step+1).to_f / steps
      scroll   = ((done - current)*amount).floor
      post scroll_event( units, scroll )
      current += (scroll.to_f)/amount
    end
  end

  ##
  # Left click, defaults to clicking at the current position.
  #
  # @param [CGPoint] point
  def click point = current_position
    left_click_down point
    left_click_up   point
  end

  ##
  # Right click, defaults to clicking at the current position.
  #
  # @param [CGPoint] point
  def right_click point = current_position
    right_click_down point
    right_click_up   point
  end


  private

  FPS     = 120
  QUANTUM = Rational(1, FPS)

  def current_position
    NSEvent.mouseLocation.carbonize!
  end

  def mouse_event action, point, object
    CGEventCreateMouseEvent( nil, action, point, object )
  end

  def scroll_event units, amount
    # the fixnum arg represents the number of scroll wheels
    # on the mouse we are simulating (up to 3)
    CGEventCreateScrollWheelEvent( nil, units, 1, amount )
  end

  def post event
    CGEventPost( KCGHIDEventTap, event )
    sleep QUANTUM
  end

  def animate_event event, button, from, to, duration
    steps = (FPS * duration).floor
    xstep = ((to.x - from.x) / steps)
    ystep = ((to.y - from.y) / steps)
    steps.times do
      from.x += xstep
      from.y += ystep
      post mouse_event( event, from, button )
    end
    $stderr.puts 'Not moving anywhere' if current == point
    post mouse_event( event, to, button )
  end

  def move from, to, duration
    animate_event( KCGEventMouseMoved, KCGMouseButtonLeft, from, to, duration )
  end

  def left_drag from, to, duration
    animate_event( KCGEventLeftMouseDragged, KCGMouseButtonLeft, from, to, duration )
  end

  def left_click_down point
    post mouse_event( KCGEventLeftMouseDown, point, KCGMouseButtonLeft )
  end
  def left_click_up point
    post mouse_event( KCGEventLeftMouseUp,   point, KCGMouseButtonLeft )
  end

  def right_click_down point
    post mouse_event( KCGEventRightMouseDown, point, KCGMouseButtonRight )
  end
  def right_click_up point
    post mouse_event( KCGEventRightMouseUp,   point, KCGMouseButtonRight )
  end

  def click_down button, point
    post mouse_event( KCGEventOtherMouseDown, point, button )
  end
  def click_up button, point
    post mouse_event( KCGEventOtherMouseUp,   point, button )
  end

  def unit_constant_for units
    case units
    when :line  then KCGScrollEventUnitLine
    when :pixel then KCGScrollEventUnitPixel
    else raise ArgumentError, "#{units} is not a valid unit"
    end
  end

end
end
