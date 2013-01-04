require 'ax/element'

##
# UI element for a view that can scroll? I'm not sure how else to
# describe it, the class name says it all.
class AX::ScrollArea < AX::Element

  ##
  # Scroll through the receiver until the given element is visible.
  #
  # If you need to scroll an unknown amount of units through a scroll
  # area, or something in a scroll area (i.e. a table), you can just
  # pass the element that you are trying to get to and this method
  # will scroll to it for you.
  #
  # @example
  #
  #   scroll_area.scroll_to table.rows.last
  #
  # @param element [AX::Element]
  # @return [void]
  def scroll_to element
    return if NSContainsRect(self.bounds, element.bounds)
    Mouse.move_to self.to_point

    # calculate direction and velocity for scrolling
    direction = element.position.y > self.position.y ? -5 : 5

    Mouse.scroll direction until NSContainsRect(self.bounds, element.bounds)

    spin 0.1
  end

end
