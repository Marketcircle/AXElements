framework 'Cocoa'

def post event
  CGEventPost(KCGHIDEventTap, event)
  sleep 0.1
end

# Simple left click on a point
point = CGPoint.new(10,0)
post CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, point, KCGMouseButtonLeft)
post CGEventCreateMouseEvent(nil, KCGEventLeftMouseUp, point, KCGMouseButtonLeft)

# Simple right click on a point, note that the important arguments are the
# last three. The second and fourth arguments have to be in agreement, if
# you want the left mouse button, you have to specify in both places or it
# will not work.
point = CGPoint.new(10,0)
post CGEventCreateMouseEvent(nil, KCGEventRightMouseDown, point, KCGMouseButtonRight)
post CGEventCreateMouseEvent(nil, KCGEventRightMouseUp, point, KCGMouseButtonRight)

# A simple scroll forward and then backwards. Scrolling can be done by pixel
# or by line. According to documentation, scrolling by more than 10 pixels
# at a time can screw things up.
point = CGPoint.new(10,300)
scroll_event = CGEventCreateScrollWheelEvent(nil, KCGScrollEventUnitPixel, 1, 10)
negative_scroll_event = CGEventCreateScrollWheelEvent(nil, KCGScrollEventUnitPixel, 1, -10)
for i in 1..10; post scroll_event; end
for i in 1..10; post negative_scroll_event; end

# Scrolling by line allows the app to define what the minimum useful scroll
# unit is.
point = CGPoint.new(10,300)
scroll_event = CGEventCreateScrollWheelEvent(nil, KCGScrollEventUnitLine, 1, 10)
negative_scroll_event = CGEventCreateScrollWheelEvent(nil, KCGScrollEventUnitLine, 1, -10)
for i in 1..10; post scroll_event; end
for i in 1..10; post negative_scroll_event; end

# Generating a click with a different mouse button is a special case.
# The second argument is always KCGEventOtherMouse..., but the fourth
# argument is an integer from 2-31 indicating different buttons a mouse,
# and KCGMouseButtonCenter is equal to an integer value of 2. Values
# 0 and 1 correspond to left and right mouse buttons, respectively.
point = CGPoint.new(500,300)
post CGEventCreateMouseEvent(nil, KCGEventOtherMouseDown, point, KCGMouseButtonCenter)
post CGEventCreateMouseEvent(nil, KCGEventOtherMouseUp, point, KCGMouseButtonCenter)

# An example clicking with extra buttons
point = CGPoint.new(500,300)
post CGEventCreateMouseEvent(nil, KCGEventOtherMouseDown, point, 3)
post CGEventCreateMouseEvent(nil, KCGEventOtherMouseUp, point, 3)

# We can also move the mouse to an arbitrary position on the screen.
points = [[0,0],[100,0],[100,100],[100,200],[200,200],[300,200],[300,300],
          [300,400],[400,400],[500,400],[500,500],[500,600],[600,600],
          [700,600],[700,700],[700,800]]
events = points.map { |point|
  post CGEventCreateMouseEvent(nil,KCGEventMouseMoved,point,KCGMouseButtonLeft)
}

# We can also create drag events, but you need to have create a mouse down
# event first.
point = CGPoint.new(10,300)
post CGEventCreateMouseEvent(nil, KCGEventLeftMouseDown, point, 0)
point = CGPoint.new(300,800)
post CGEventCreateMouseEvent(nil, KCGEventLeftMouseDragged, point, 0)
post CGEventCreateMouseEvent(nil, KCGEventLeftMouseUp, point, 0)

# Similarly, we can create a drag event with the right mouse, though
# I have never seen an app that uses this functionality
point = CGPoint.new(10,300)
post CGEventCreateMouseEvent(nil, KCGEventRightMouseDown, point, 1)
point = CGPoint.new(300,800)
post CGEventCreateMouseEvent(nil, KCGEventRightMouseDragged, point, 1)
post CGEventCreateMouseEvent(nil, KCGEventRightMouseUp, point, 1)
