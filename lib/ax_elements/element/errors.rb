class AX::Element

  ##
  # Raised when a lookup fails
  class LookupFailure < ArgumentError
    def initialize element, name
      super "#{name} was not found for #{element.inspect}"
    end
  end

  ##
  # Raised when trying to set an attribute that cannot be written
  class ReadOnlyAttribute < NoMethodError
    def initialize element, name
      super "#{name} is a read only attribute for #{element.inspect}"
    end
  end

  ##
  # Raised when an implicit search fails
  class SearchFailure < NoMethodError
    def initialize searcher, searchee, filters
      path       = Accessibility.path(searcher).map! { |x| x.inspect }
      pp_filters = (filters || {}).map do |key, value|
        "#{key}: #{value.inspect}"
      end.join(', ')
      msg  = "Could not find `#{searchee}"
      msg << "(#{pp_filters})" unless pp_filters.empty?
      msg << "` as a child of #{searcher.class}"
      msg << "\nElement Path:\n\t" << path.join("\n\t")
      super msg
    end
  end

end
