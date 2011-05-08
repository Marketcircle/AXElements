module Accessibility

##
# @todo There is a lot of duplication in this class that needs to be
#       dealt with appropriately.
# @todo Search does not handle if the object does not respond to a
#       filter.
# @todo allow regex matching when filtering string attributes
# @todo make search much faster by not wrapping child classes
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
  # @param [Hash] filters
  # @return [Array<AX::Element>,Array<>]
  def find_all klass, filters = {}
    search_results = []
    until elements.empty?
      element          = elements.shift
      primary_filter ||= (AX.const_get(klass) if AX.const_defined?(klass))

      if element.attributes.include?(KAXChildrenAttribute)
        elements.concat element.attribute(KAXChildrenAttribute)
      end

      next if element.class != primary_filter
      next if filters.find do |filter, value|
        element.get_attribute(filter) != value # this is the expensive step
      end

      search_results << element
    end
    search_results
  end

  ##
  # Find the first element in the tree that has a certain type and
  # matches any other criteria that has been specified.
  #
  # @param [String] target_klass
  # @param [Hash] filters
  # @return [AX::Element,nil]
  def find klass, filters = {}
    until elements.empty?
      element          = elements.shift
      primary_filter ||= (AX.const_get(klass) if AX.const_defined?(klass))

      if element.attributes.include?(KAXChildrenAttribute)
        elements.concat element.attribute(KAXChildrenAttribute)
      end

      next if element.class != primary_filter
      next if filters.find do |filter, value|
        element.get_attribute(filter) != value # this is the expensive step
      end

      return element
    end
  end

end
end
