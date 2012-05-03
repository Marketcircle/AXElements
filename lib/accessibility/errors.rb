require 'accessibility/qualifier'

##
# Error raised when an implicit search fails to return a result.
class Accessibility::SearchFailure < NoMethodError

  # @param searcher [AX::Element]
  # @param searchee [#to_s]
  # @param filters [Hash{Symbol=>Object}]
  # @yield Optional block that would have been used for a search filter
  def initialize searcher, searchee, filters, &block
    filters = {} unless filters.kind_of? Hash
    msg  = "Could not find `#{pp_searchee searchee, filters, &block}` "
    msg << "as a child of #{searcher.class}\n"
    msg << "Element Path:\n\t" << path_to(searcher)
    # @todo Consider turning this on by default
    msg << "\nSubtree:\n\n" << searcher.inspect_subtree if Accessibility.debug?
    super msg
  end


  private

  # Nice string representation of what was being searched for
  def pp_searchee searchee, filters, &block
    Accessibility::Qualifier.new(searchee, filters, &block).describe
  end

  # Nice string representation of element's path from the application root
  def path_to element
    element.ancestry.map! { |x| x.inspect }.join("\n\t")
  end

end
