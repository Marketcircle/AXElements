module AX
class Element

  ##
  # You are expected to make sure you are not calling {#search} on an
  # object that has no children, you will cause an infinite loop if you
  # do not.
  #
  # @param [Symbol] element_type
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,Array<AX::Element>,Array<>,nil]
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
