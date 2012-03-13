require 'accessibility/debug'

module Accessibility

  ##
  # Error raised when a dynamic attribute lookup fails.
  class LookupFailure < ArgumentError
    def initialize element, name
      super "#{name.inspect} was not found for #{element.inspect}"
    end
  end

  ##
  # Error raised when an implicit search fails to return a result.
  class SearchFailure < NoMethodError

    def initialize searcher, searchee, filters
      filters = {} unless filters.kind_of? Hash
      msg  = "Could not find `#{searchee}#{filters.ax_pp}` "
      msg << "as a child of #{searcher.class}\n"
      msg << "Element Path:\n\t" << path_to(searcher)
      # @todo Consider turning this on by default
      if Accessibility::Debug.on?
        msg << "\nSubtree:\n\t" << Accessibility::Debug.text_subtree(searcher)
      end
      super msg
    end


    private

    def path_to element
      Accessibility::Debug.path(element).map! { |x| x.inspect }.join("\n\t")
    end
  end

end
