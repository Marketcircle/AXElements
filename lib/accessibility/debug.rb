##
# Collection of utility methods helpful when trying to debug issues.
module Accessibility::Debug

  # Initialize the DEBUG value
  @on = if ENV['AXDEBUG']
          ENV['AXDEBUG'] == 'true'
        else
          $DEBUG
        end


  class << self

    ##
    # Whether or not to turn on DEBUG features in AXElements. The
    # value is initially inherited from `$DEBUG` but can be overridden
    # by an environment variable named `AXDEBUG` or changed dynamically
    # at runtime.
    #
    # @return [Boolean]
    attr_accessor :on
    alias_method :on?, :on

    ##
    # Get a list of elements, starting with an element you give, and riding
    # the hierarchy up to the top level object (i.e. the {AX::Application}).
    #
    # @example
    #
    #   element = AX::DOCK.list.application_dock_item
    #   path_for element
    #     # => [AX::ApplicationDockItem, AX::List, AX::Application]
    #
    # @param [AX::Element]
    # @return [Array<AX::Element>] the path in ascending order
    def path *elements
      element = elements.last
      return path(elements << element.parent) if element.respond_to? :parent
      return elements
    end

    ##
    # @note This is an unfinished feature
    #
    # Make a `dot` format graph of the tree, meant for graphing with
    # GraphViz.
    #
    # @return [String]
    def graph_subtree root
      require 'accessibility/graph'
      dot = Accessibility::Graph.new(root)
      dot.build!
      dot.to_s
    end

    ##
    # Dump a tree to the console, indenting for each level down the
    # tree that we go, and inspecting each element.
    #
    # @example
    #
    #   puts subtree_for app
    #
    # @return [String]
    def text_subtree element
      output = element.inspect + "\n"
      # @todo should use each_child_with_level instead
      enum   = Accessibility::Enumerators::DepthFirst.new element
      enum.each_with_level do |element, depth|
        output << "\t"*depth + element.inspect + "\n"
      end
      output
    end

    ##
    # Highlight an element on screen. You can optionally specify the
    # highlight colour or pass a timeout to automatically have the
    # highlighter disappear.
    #
    # The highlighter is actually a window, so if you do not set a
    # timeout, you will need to call `#stop` or `#close` on the `NSWindow`
    # object that this method returns in order to get rid of the
    # highlighter.
    #
    # You could use this method to highlight an arbitrary number of
    # elements on screen, with a rainbow of colours for debugging.
    #
    # @example
    #
    #   highlighter = highlight window.outline
    #   highlight window.outline.row, colour: NSColor.greenColor, timeout: 5
    #   highlighter.stop
    #
    # @param [AX::Element]
    # @param [Hash] opts
    # @option opts [Number] :timeout
    # @option opts [NSColor] :colour
    # @return [NSWindow]
    def highlight element, opts = {}
      app    = NSApplication.sharedApplication
      colour = opts[:colour] || opts[:color] || NSColor.magentaColor
      window = highlight_window_for element.bounds, colour
      kill window, after: opts[:timeout] if opts.has_key? :timeout
      window
    end


    private

    # @param [NSWindow]
    # @param [Number]
    def kill window, after: time
      @kill_queue ||= Dispatch::Queue.new 'com.marketcircle.AXElements'
      @kill_queue.async do
        sleep time
        window.close
      end
    end

    ##
    # Create the window that acts as the highlighted portion of the screen.
    #
    # @param [NSRect]
    # @param [NSColor]
    # @return [NSWindow]
    def highlight_window_for bounds, colour
      bounds.flip!
      window = NSWindow.alloc.initWithContentRect bounds,
                                       styleMask: NSBorderlessWindowMask,
                                         backing: NSBackingStoreBuffered,
                                           defer: true

      window.setOpaque false
      window.setAlphaValue 0.20
      window.setLevel NSStatusWindowLevel
      window.setBackgroundColor colour
      window.setIgnoresMouseEvents true
      window.setFrame bounds, display: false
      window.makeKeyAndOrderFront NSApp
      def window.stop
        close
      end
      window
    end

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
