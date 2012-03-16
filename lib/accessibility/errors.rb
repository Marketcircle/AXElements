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
      msg  = "Could not find `#{pp_searchee searchee, filters}` "
      msg << "as a child of #{searcher.class}\n"
      msg << "Element Path:\n\t" << path_to(searcher)
      # @todo Consider turning this on by default
      msg << "\nSubtree:\n\t" << debug(searcher) if Accessibility::Debug.on?
      super msg
    end


    private

    def pp_searchee searchee, filters
      Accessibility::Qualifier.new(searchee, filters).inspect
    end

    def path_to element
      Accessibility::Debug.path(element).map! { |x| x.inspect }.join("\n\t")
    end

    def debug searcher
      Accessibility::Debug.text_subtree(searcher)
    end
  end

end

##
# Extensions to `NSDictionary`.
class NSDictionary
  ##
  # Format the hash for AXElements pretty printing.
  #
  # @return [String]
  def ax_pp
    return ::EMPTY_STRING if empty?

    list = map { |k, v|
      case v
      when Hash
        "#{k}#{v.ax_pp}"
      else
        "#{k}: #{v.inspect}"
      end
    }
    "(#{list.join(', ')})"
  end
end
