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
    @sym = klass
    compile criteria
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
  # Take a hash of search filters and generate an optimized search
  #
  # @param [Hash]
  def compile criteria
    @filters = criteria.map do |key, value|
      if value.kind_of? Hash
        [:subsearch, key, value]
      elsif key.kind_of? Array
        if value.kind_of? Regexp
          [:parameterized_match, *key, value]
        else
          [:parameterized_equality, *key, value]
        end
      elsif value.kind_of? Regexp
        [:match, key, value]
      else
        [:equality, key, value]
      end
    end
  end

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
  # Determines if the element meets all the criteria of the filters,
  # spawning sub-searches if necessary.
  #
  # @param [AX::Element]
  def meets_criteria? element
    @filters.all? do |filter|
      self.send *filter, element
    end
  end

  def subsearch klass, criteria, element
    if element.attributes.include? :children
      !element.search(klass, criteria).blank?
    end
  end

  def match attr, regexp, element
    if element.attributes.include? attr
      element.attribute(attr).match regexp
    end
  end

  def equality attr, value, element
    if element.attributes.include? attr
      element.attribute(attr) == value
    end
  end

  def parameterized_match attr, param, regexp, element
    if element.parameterized_attributes.include? attr
      element.parameterized_attribute(attr, param).match regexp
    end
  end

  def parameterized_equality attr, param, value, element
    if element.parameterized_attributes.include? attr
      element.parameterized_attribute(attr, param) == regexp
    end
  end

end
