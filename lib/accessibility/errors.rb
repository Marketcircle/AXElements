require 'accessibility/debug'

##
# Error raised when an implicit search fails to return a result.
class Accessibility::SearchFailure < NoMethodError

  def initialize searcher, searchee, filters
    filters = {} unless filters.kind_of? Hash
    msg  = "Could not find `#{pp_searchee searchee, filters}` "
    msg << "as a child of #{searcher.class}\n"
    msg << "Element Path:\n\t" << path_to(searcher)
    # @todo Consider turning this on by default
    msg << "\nSubtree:\n\t" << debug(searcher) if Accessibility::Debug.on?
    super msg
  end


  private

  def pp_searchee searchee, filters
    Accessibility::Qualifier.new(searchee, filters).describe
  end

  def path_to element
    Accessibility::Debug.path(element).map! { |x| x.inspect }.join("\n\t")
  end

  def debug searcher
    Accessibility::Debug.text_subtree(searcher)
  end

end
