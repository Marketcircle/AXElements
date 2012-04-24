require 'accessibility/qualifier'

##
# Error raised when an implicit search fails to return a result.
class Accessibility::SearchFailure < NoMethodError

  # @param [AX::Element]
  # @param [#to_s]
  # @param [Hash{Symbol=>Object}]
  def initialize searcher, searchee, filters
    filters = {} unless filters.kind_of? Hash
    msg  = "Could not find `#{pp_searchee searchee, filters}` "
    msg << "as a child of #{searcher.class}\n"
    msg << "Element Path:\n\t" << path_to(searcher)
    # @todo Consider turning this on by default
    msg << "\nSubtree:\n\n" << subtree_for(searcher) if Accessibility.debug?
    super msg
  end


  private

  # Nice string representation of what was being searched for
  def pp_searchee searchee, filters
    Accessibility::Qualifier.new(searchee, filters).describe
  end

  # Nice string representation of element's path from the application root
  def path_to element
    element.ancestry.map! { |x| x.inspect }.join("\n\t")
  end

end
