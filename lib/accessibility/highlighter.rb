framework 'AppKit'
require   'accessibility/version'

##
# A screen highlighter for debugging. When you initialize a highligter
# object it will highlight the given bounds on the screen.
#
# Highligter objects can have their colour configured at initialization,
# and can also have a timeout to automatically stop displaying.
#
# @example
#
#   h = Accessibility::Highlighter.new(CGRectMake(100,100,100,100))
#   # when you are done...
#   h.stop
#
class Accessibility::Highlighter < NSWindow

  # @param [CGRect]
  # @param [Hash] opts
  # @option opts [Number] :timeout
  # @option opts [NSColor] :colour (NSColor.magentaColor)
  def initialize bounds, opts = {}
    colour = opts[:colour] || opts[:color] || NSColor.magentaColor

    bounds.flip! # we assume the rect is in the other co-ordinate system

    initWithContentRect bounds,
             styleMask: NSBorderlessWindowMask,
               backing: NSBackingStoreBuffered,
                 defer: true
    setOpaque false
    setAlphaValue 0.20
    setLevel NSStatusWindowLevel
    setBackgroundColor colour
    setIgnoresMouseEvents true
    setFrame bounds, display: false
    makeKeyAndOrderFront NSApp

    if opts.has_key? :timeout
      Dispatch::Queue.new(queue_id).after opts[:timeout] do
        self.stop
      end
    end
  end

  ##
  # Tell the highlighter to stop displaying.
  #
  # @return [self]
  def stop
    close
  end


  private

  def queue_id
    "com.marketcircle.axelements.window_killer_#{hash}"
  end
end


##
# AXElements extensions to `CGRect`.
class CGRect
  ##
  # Treats the rect as belonging to one co-ordinate system and then
  # converts it to the other system.
  #
  # This is useful because accessibility API's expect to work with
  # the flipped co-ordinate system (origin in top left), but AppKit
  # prefers to use the cartesian co-ordinate system (origin in bottom
  # left).
  #
  # @return [CGRect]
  def flip!
    screen_height = NSMaxY(NSScreen.mainScreen.frame)
    origin.y      = screen_height - NSMaxY(self)
    self
  end
end


# Initialize the shared application so that windows can be created
NSApplication.sharedApplication
