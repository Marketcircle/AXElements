##
# @todo Search does not handle if the object does not respond to a
#       filter. Though, this is implicitly a low risk scenario.
# @todo Make search much faster by not wrapping child classes
#
# Represents a search entity. Searches through a view hierarchy are
# breadth first.
#
# Search can be slow if it has to go too many levels deep to find an
# object (or confirm that an object does not exist). This could be sped
# up in the future by iterating over low level AXUIElementRef objects
# instead of the wrapped {AX::Element} objects.
class Accessibility::Search

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
