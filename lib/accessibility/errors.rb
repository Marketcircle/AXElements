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
      msg  = "Could not find `#{searchee}#{pp_filters(filters)}` "
      msg << "as a child of #{searcher.class}\n"
      msg << "Element Path:\n\t" << path_to(searcher)
      # @todo Consider turning this on by default
      if Accessibility::Debug.on?
        msg << "\nSubtree:\n\t" << Accessibility::Debug.text_subtree(searcher)
      end
      super msg
    end


    private

    # @return [String]
    def pp_filters filters
      return ::EMPTY_STRING if filters.empty?

      list = filters.map { |k, v| "#{k}: #{v.inspect}" }
      "(#{list.join(', ')})"
    end

    def path_to element
      Accessibility::Debug.path(element).map! { |x| x.inspect }.join("\n\t")
    end
  end

end
