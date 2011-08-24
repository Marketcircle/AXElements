##
# [Reference](http://developer.apple.com/library/mac/#documentation/Carbon/Reference/QuartzEventServicesRef/Reference/reference.html).
#
# @todo Add inertial scrolling abilities?
# @todo Bezier paths for movements
# @todo Less discrimination against left handed people
# @todo A more intelligent default duration
# @todo Point arguments should accept a pair tuple
module Mouse; end

class << Mouse

  ##
  # Move the mouse from wherever it is to any given point.
  #
  # @param [CGPoint] point
  # @param [Float] duration animation duration, in seconds
  def move_to point, duration = 0.2
    animate_event KCGEventMouseMoved, KCGMouseButtonLeft, current_position, point, duration
  end

  ##
  # Click and drag from the current mouse position to any
  # given point.
  #
  # @param [CGPoint] point
  # @param [Float] duration animation duration, in seconds
  def drag_to point, duration = 0.2
    click point do
      animate_event KCGEventLeftMouseDragged, KCGMouseButtonLeft, current_position, point, duration
    end
  end

  ##
  # @todo Need to double check to see if I introduce any inaccuracies.
  #
  # Scrolling too much or too little in a period of time will cause the
  # animation to look weird, possibly causing the app to mess things up.
  #
  # @param [Fixnum] amount number of pixels/lines to scroll; positive
  #   to scroll up or negative to scroll down
  # @param [Float] duration animation duration, in seconds
  # @param [Fixnum] units :line scrolls by line, :pixel scrolls by pixel
  def scroll amount, duration = 0.2, units = :line
    units   = UNIT[units] || raise(ArgumentError, "#{units} is not a valid unit")
    steps   = (FPS * duration).floor
    current = 0.0
    steps.times do |step|
      done     = (step+1).to_f / steps
      scroll   = ((done - current)*amount).floor
      # the fixnum arg represents the number of scroll wheels
      # on the mouse we are simulating (up to 3)
      post CGEventCreateScrollWheelEvent(nil, units, 1, scroll)
      current += scroll.to_f / amount
    end
  end

  ##
  # Left click, defaults to clicking at the current position.
  #
  # @yield You can pass a block that will be executed after clicking down
  #        but before clicking up
  # @param [CGPoint] point
  def click point = current_position
    post mouse_event KCGEventLeftMouseDown, point, KCGMouseButtonLeft
    yield if block_given?
    post mouse_event KCGEventLeftMouseUp,   point, KCGMouseButtonLeft
  end

  ##
  # Right click, defaults to clicking at the current position.
  #
  # @yield You can pass a block that will be executed after clicking down
  #        but before clicking up
  # @param [CGPoint] point
  def right_click point = current_position
    post mouse_event KCGEventRightMouseDown, point, KCGMouseButtonRight
    yield if block_given?
    post mouse_event KCGEventRightMouseUp,   point, KCGMouseButtonRight
  end

  ##
  # Perform a double left click at an arbitrary point. Defaults to clicking
  # at the current position.
  #
  # @param [CGPoint] point
  def double_click point = current_position
    event = CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, point, KCGMouseButtonLeft)
    CGEventPost(KCGHIDEventTap, event)
    CGEventSetType(event,       KCGEventLeftMouseUp)
    CGEventPost(KCGHIDEventTap, event)

    CGEventSetIntegerValueField(event, KCGMouseEventClickState, 2)
    CGEventSetType(event,       KCGEventLeftMouseDown)
    CGEventPost(KCGHIDEventTap, event)
    CGEventSetType(event,       KCGEventLeftMouseUp)
    CGEventPost(KCGHIDEventTap, event)
  end

  ##
  # Click with an arbitrary mouse button, using numbers to represent
  # the mouse button. The left button is 0, right button is 1, middle
  # button is 2, and the rest are not documented!
  #
  # @param [CGPoint]
  # @param [Number]
  def arbitrary_click point = current_position, button = KCGMouseButtonCenter
    post mouse_event KCGEventOtherMouseDown, point, button
    post mouse_event KCGEventOtherMouseUp,   point, button
  end

  ##
  # Return the coordinates of the mouse using the flipped coordinate
  # system.
  #
  # @return [CGPoint]
  def current_position
    CGEventGetLocation(CGEventCreate(nil))
  end

  ##
  # Number of animation steps per second
  #
  # @return [Number]
  FPS     = 120

  ##
  # @note We keep the number as a rational to try and avoid rounding
  #       error introduced by the way MacRuby deals with floats.
  #
  # Smallest unit of time allowed for an animation step.
  #
  # @return [Number]
  QUANTUM = Rational(1, FPS)

  ##
  # Available unit constants when scrolling.
  #
  # @return [Hash{Symbol=>Fixnum}]
  UNIT = {
    line:  KCGScrollEventUnitLine,
    pixel: KCGScrollEventUnitPixel
  }


  private

  def post event
    CGEventPost(KCGHIDEventTap, event)
    sleep QUANTUM
  end

  def mouse_event action, point, object
    CGEventCreateMouseEvent(nil, action, point, object)
  end

  def animate_event event, button, from, to, duration
    steps = (FPS * duration).floor
    xstep = (to.x - from.x) / steps
    ystep = (to.y - from.y) / steps
    steps.times do
      from.x += xstep
      from.y += ystep
      post mouse_event(event, from, button)
    end
    $stderr.puts 'Not moving anywhere' if from == to
    post mouse_event(event, to, button)
  end

end
