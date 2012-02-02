require 'accessibility/graph'

module Accessibility::Debug

  ##
  # Get a list of elements, starting with an element you give, and riding
  # the hierarchy up to the top level object (i.e. the {AX::Application}).
  #
  # @example
  #
  #   element = AX::DOCK.list.application_dock_item
  #   path_for element # => [AX::ApplicationDockItem, AX::List, AX::Application]
  #
  # @param [AX::Element]
  # @return [Array<AX::Element>] the path in ascending order
  def path_for *elements
    element = elements.last
    return path_for(elements << element.parent) if element.respond_to? :parent
    return elements
  end

  ##
  # @note This is an unfinished feature
  #
  # Make a `dot` format graph of the tree, meant for graphing with
  # GraphViz.
  #
  # @return [String]
  def graph_for root
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
  #   puts dump_for app
  #
  # @return [String]
  def dump_for element
    output = element.inspect + "\n"
    # @todo should use each_child_with_level instead
    enum   = Accessibility::Enumerators::DepthFirst.new element
    enum.each_with_level do |element, depth|
      output << "\t"*depth + element.inspect + "\n"
    end
    output
  end

  ##
  # Highlight an element on screen. You can optionally pass the amount
  # of time you wish for the item to be highlighted.
  #
  # @param [AX::Element]
  # @param [NSColor]
  # @param [Number]
  def highlight element, time = 5.0, colour = NSColor.redColor
    app = NSApplication.sharedApplication
    app.delegate = self
    @window = highlight_window_for element.bounds, colour
    @sleep  = time
    app.run
    @window
  end

  # @private
  def applicationDidFinishLaunching sender
    sleep @sleep
    @window.close
    NSApplication.sharedApplication.stop self
  end


  private

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
    window
  end
end
