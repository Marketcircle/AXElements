module AX
class Element

  ##
  # @todo allow regex matching when filtering string attributes
  # @todo decide whether plural or singular search before entering
  #       the main loop
  # @todo make search much faster by not wrapping child classes
  #
  # @note You are expected to make sure you are not calling {#search} on
  #       an object that has no children, you will cause an infinite loop
  #       if you do not.
  #
  # Perform a breadth first search through the view hierarchy rooted at
  # the current element.
  #
  # See the documentation page [Searching](file/Searching.markdown)
  # on the details of how to search.
  #
  # @example Find the dock item for the Finder app
  #  AX::DOCK.search( :application_dock_item, title: 'Finder' )
  #
  # @param [Symbol] element_type
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search element_type, filters = {}
    elements       = AX.attr_of_element(@ref, KAXChildrenAttribute)
    search_results = []
    class_const    = element_type.to_s.camelize!

    until elements.empty?
      element          = elements.shift
      primary_filter ||= AX.plural_const_get(class_const)

      if element.attributes.include?(KAXChildrenAttribute)
        elements.concat( element.get_attribute :children )
      end

      next unless element.class == primary_filter
      next if filters.find { |filter,value| element.send(filter) != value }

      return element unless element_type.to_s[-1] == 's'
      search_results << element
    end

    element_type.to_s[-1] == 's' ? search_results : nil
  end

end
end
