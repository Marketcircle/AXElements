##
# Used in searches to answer whether or not a given element meets the
# expected criteria.
class Accessibility::Qualifier

  # @return [Hash]
  #attr_reader :criteria

  ##
  # Initialize a qualifier with the kind of object that you want to
  # qualify and a dictionary of filter criteria.
  #
  # @param [String,Symbol] klass
  # @param [Hash] criteria
  def initialize klass, criteria
    @sym      = klass
    @criteria = criteria
  end

  ##
  # Whether or not a candidate object matches the criteria given
  # at initialization.
  #
  # @param [AX::Element] element
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
  # @param [AX::Element] element
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
  #       optimized filter qualifier. eval is not an option.
  #
  # Determines if the element meets all the criteria of the filters,
  # spawning sub-searches if necessary.
  #
  # @param [AX::Element] element
  def meets_criteria? element
    @criteria.all? do |filter, value|
      if value.kind_of? Hash
        if element.attributes.include? KAXChildrenAttribute
          !element.search(filter, value).blank?
        else
          false
        end
      elsif element.respond_to? filter
        element.send(filter) == value
      else # this legitimately occurs
        false
      end
    end
  end

end
