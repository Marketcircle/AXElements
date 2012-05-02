require 'ax/element'
require 'mouse'

##
# UI element representing a menu. Not much to it...
class AX::Menu < AX::Element

  ##
  # Scroll the menu until the given element, which must be in the menu
  # is visible in the bounds of the menu. This method will also move the
  # mouse pointer to the given element.
  #
  # If you need to scroll an unknown number of units through a menu,
  # you can just pass the element that you need visible and this method
  # will scroll to it for you.
  #
  # @example
  #
  #   click window.pop_up do
  #     menu = pop_up.menu
  #     menu.scroll_to menu.item(title: "Expensive Cake")
  #   end
  #
  # @param [AX::Element] element
  # @return [void]
  def scroll_to element
    Mouse.move_to self.to_point

    # calculate which scroll arrow to move to
    fudge_factor = self.item.size.height * 0.1
    point = self.position
    size  = self.size
    point.x += size.width / 2
    point.y += if element.position.y > point.y
                 size.height - fudge_factor
               else
                 fudge_factor
               end

    # scroll until element is visible
    until NSContainsRect(self.bounds, element.bounds)
      Mouse.move_to point
    end

    start = Time.now
    until Time.now - start > 5
      # Sometimes the little arrow bars in menus covering
      # up the menu item and we have to move just a bit more.
      if self.application.element_at(Mouse.current_position) != element
        Mouse.move_to element.to_point
      else
        break
      end
    end
  end

  ##
  # Search the menu for a `menu_item` that matches the given
  # filters. The filters should be specified just as they would
  # be when calling {#search}.
  #
  # @param [Hash] filters
  # @yield Optional block used for search filtering
  # @return [AX::Element]
  def item filters = {}, &block
    result = self.search :menu_item, filters, &block
    return result unless result.blank?
    raise Accessibility::SearchFailure.new(self, :menu_item, filters, &block)
  end

end
