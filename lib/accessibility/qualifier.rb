##
# Used in searches to answer whether or not a given element meets the
# expected criteria.
class Accessibility::Qualifier

  ##
  # Initialize a qualifier with the kind of object that you want to
  # qualify and a dictionary of filter criteria.
  #
  # @example
  #
  #   Accessibility::Qualifier.new(:StandardWindow, title: 'Test')
  #   Accessibility::Qualifier.new(:Button, {})
  #   Accessibility::Qualifier.new(:Table, { row: { title: /Price/ } })
  #
  # @param [#to_s] klass
  # @param [Hash]
  def initialize klass, criteria
    @sym      = klass
    @criteria = criteria
  end

  ##
  # Whether or not a candidate object matches the criteria given
  # at initialization.
  #
  # @param [AX::Element]
  def qualifies? element
    return false unless the_right_type? element
    return false unless meets_criteria? element
    return true
  end


  private

  ##
  # Checks if a candidate object is of the correct class, respecting
  # that that the class being searched for may not be defined yet.
  #
  # @param [AX::Element]
  def the_right_type? element
    unless @klass
      if AX.const_defined? @sym
        @klass = AX.const_get @sym
      else
        return false
      end
    end
    return element.kind_of? @klass
  end

  ##
  # @todo How could we handle filters that use parameterized
  #       attributes?
  # @todo Optimize searching by compiling filters into an
  #       optimized filter qualifier. `eval` is not an option.
  #
  # Determines if the element meets all the criteria of the filters,
  # spawning sub-searches if necessary.
  #
  # @param [AX::Element]
  def meets_criteria? element
    @criteria.all? do |filter, value|
      if value.kind_of? Hash
        if element.respond_to? :children
          !element.search(filter, value).blank?
        end

      elsif element.respond_to? filter
        element_value = element.send(filter)
        if value.kind_of? Regexp
          element_value.to_s.match value
        else
          element_value == value
        end

      end
    end
  end

end
