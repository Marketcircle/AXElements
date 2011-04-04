module AX
class Element

  ##
  # @todo allow regex matching when filtering string attributes
  # @todo decide whether plural or singular search before entering
  #       the main loop
  # @todo consider adding safety check for children existence
  # @todo move most of the documentation for this method to its own
  #       file in /docs
  # @todo make search much faster by not wrapping child classes
  #
  # @note You are expected to make sure you are not calling {#search} on
  #       an object that has no children, you will cause an infinite loop
  #       if you do not.
  #
  # Search works by looking at the child elements of the current element,
  # and possibily at the children of the children elements, and so on and
  # so forth in a breadth first search through the UI hierarchy rooted at
  # the current node.
  #
  # There are two features of the search that are important with regards
  # results of the search: pluralization and filtering.
  #
  # Filtering is the important part of a search. The first argument of this
  # method, the element_type, is the first, and only mandatory, filter; the
  # element_type filters on the class of an element.
  #
  # Additional filters are specified as key/value pairs, where the key is a
  # method to call on a child element and the value must match or the child
  # does not match the search. You can attach as many filters as you want.
  #
  # The other search feature is pluralization, which is when an 's' is
  # appended to the element_type that you are searching for; this causes
  # the search to assume that you wanted every element in the UI hierarchy
  # that meets the filtering criteria. However, this causes the search to be
  # very slow (~1 second) and is meant more for prototying tests and
  # debugging broken tests, but can also be used to make sure items are no
  # longer on screen.
  #
  # If you do not pluralize, then the first element that meets all the
  # filtering criteria will be returned.
  #
  # @param [Symbol] element_type
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search element_type, filters = {}
    elements         = self.children # seed the search array
    search_results   = []
    class_const      = element_type.to_s.camelize!
    filters        ||= {}

    until elements.empty?
      element          = elements.shift
      primary_filter ||= AX.plural_const_get(class_const)

      elements.concat(element.children) if element.attributes.include?(KAXChildrenAttribute)

      next unless element.class == primary_filter
      next if filters.find { |filter| element.send(filter[0]) != filter[1] }

      return element unless element_type.to_s[-1] == 's'
      search_results << element
    end

    return search_results if element_type.to_s[-1] == 's'
    return search_results.first
  end

end
end
