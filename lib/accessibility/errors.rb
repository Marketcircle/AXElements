require 'accessibility/debug'

module Accessibility

  ##
  # Error raised when a dynamic attribute lookup fails.
  class LookupFailure < ArgumentError
    def initialize element, name
      super "#{name} was not found for #{element.inspect}"
    end
  end

  ##
  # Error raised when an implicit search fails to return a result.
  class SearchFailure < NoMethodError
    include Accessibility::Debug

    def initialize searcher, searchee, filters
      filters = {} unless filters.kind_of? Hash
      msg  = "Could not find `#{searchee}#{pp_filters(filters)}` "
      msg << "as a child of #{searcher.class}\n"
      msg << "Element Path:\n\t" << path(searcher)
      super msg
    end


    private

    # @return [String,nil]
    def pp_filters filters
      return unless filters
      return if     filters.empty?

      list = filters.map { |k, v| "#{k}: #{v.inspect}" }
      "(#{list.join(', ')})"
    end

    def path element
      path_for(element).map! { |x| x.inspect }.join("\n\t")
    end
  end

end
