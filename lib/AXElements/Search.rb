module Accessibility

##
# @todo There is a lot of duplication in this class that needs to be
#       dealt with appropriately.
# @todo Search does not handle if the object does not respond to a
#       filter. Though, this is implicitly a low risk scenario.
# @todo Make search much faster by not wrapping child classes
# @todo Allow regex matching when filtering string attributes
# @todo Conceptually, when you are writing a test filter, you have the
#       key and the value. The key is always a property (attribute) of
#       the element that is being searched for; but the meaning of the
#       key is influenced the class of the value and the class of the
#       key. In most cases, things are very simple because the class
#       of the key matches the class of the value and they can just be
#       tested for equality. However, if the classes do not match, you
#       need a heuristic to decide what to do. As an example, if the
#       value is a regexp, then the key needs to respond to #match, but
#       it might be an Element (which does not respond to #match), so
#       you have to look at an attribute on the Element which would
#       respond to #match, which is probably a title or a value. In the
#       case of the title ui element, it is obvious that we would want
#       to extract the title attribute when matching against a regexp
#       or a string. Other cases still need to be explored. A possible
#       implementation for such a system would use lookup tables to
#       match a class to a list of possible methods or a list of attributes
#       that could be checked.
#
# Represents a search entity. Searches through a view hierarchy are
# breadth first.
#
# Search can be slow if it has to go too many levels deep to find an
# object (or confirm that an object does not exist). This could be sped
# up in the future by iterating over low level AXUIElementRef objects
# instead of the wrapped {AX::Element} objects.
class Search

  # @return [Array<AX::Element>]
  attr_accessor :elements

  # @return [AX::Element]
  attr_accessor :element

  # @return [Class] The target class from the AX namespace
  attr_accessor :target

  # @return [Hash{Symbol=>Object}] Hash of filters (requirements) that
  #   an element must meet in order to match
  attr_accessor :filters

  # @param [AX::Element] root
  def initialize root
    root.attributes.include?(KAXChildrenAttribute) ?
      (self.elements = root.attribute(KAXChildrenAttribute)) :
      raise(ArgumentError, "Cannot search #{root.inspect} as it has no children")
  end

  ##
  # Find all elements in the view hierarchy that match the given class
  # and any other search criteria.
  #
  # @param [String] target_klass
  # @param [Hash] criteria
  # @return [Array<AX::Element>,Array<>]
  def find_all klass, criteria = {}
    search_results = []
    self.filters = criteria
    until elements.empty?
      self.element = elements.shift
      append_children
      self.target ||= AX.const_get(klass) if AX.const_defined?(klass)
      next unless matches_criteria?
      search_results << element
    end
    search_results
  end

  ##
  # Find the first element in the tree that has a certain type and
  # matches any other criteria that has been specified.
  #
  # @param [String] target_klass
  # @param [Hash] criteria
  # @return [AX::Element,nil]
  def find klass, criteria = {}
    self.filters = criteria
    until elements.empty?
      self.element = elements.shift
      append_children
      self.target ||= AX.const_get(klass) if AX.const_defined?(klass)
      next unless matches_criteria?
      return element
    end
  end


  private

  def append_children
    if element.attributes.include?(KAXChildrenAttribute)
      elements.concat element.attribute(KAXChildrenAttribute)
    end
  end

  def matches_criteria?
    return false if element.class != self.target
    return false if self.filters.find do |filter, value|
      filter_value = element.get_attribute(filter)
      if filter_value.class == value.class
        filter_value != value
      else
        filter_value.attribute(TABLE[filter]) != value
      end
    end
    return true
  end

  TABLE = {
    title_ui_element: KAXValueAttribute
  }

end
end
