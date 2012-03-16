##
# Used in searches to answer whether or not a given element meets the
# expected criteria.
class Accessibility::Qualifier

  ##
  # Initialize a qualifier with the kind of object that you want to
  # qualify and a dictionary of filter criteria. You can optionally
  # pass a block if your qualification criteria is too complicated
  # for key/value pairs and the blocks return value will be used to
  # determine if an element qualifies.
  #
  # @example
  #
  #   Accessibility::Qualifier.new(:standard_window, title: 'Test')
  #   Accessibility::Qualifier.new(:buttons, {})
  #   Accessibility::Qualifier.new(:Table, { row: { title: /Price/ } })
  #   Accessibility::Qualifier.new(:element) do |element|
  #     element.children.size > 5 && NSContainsRect(element.bounds, rect)
  #   end
  #
  # @param [#to_s] klass
  # @param [Hash]
  # @yield Optional block that can qualify an element
  def initialize klass, criteria
    @klass    = TRANSLATOR.classify(klass)
    @criteria = criteria
    @block    = Proc.new if block_given?
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

  # @return [String]
  def describe
    "#{@klass}#{@criteria.ax_pp}#{@block ? '[✔]' : ::EMPTY_STRING}"
  end


  private

  ##
  # @private
  #
  # Local reference to the {Accessibility::Translator}.
  #
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

  ##
  # Take a hash of search filters and generate an optimized search
  #
  # @param [Hash]
  def compile criteria
    @filters = criteria.map do |key, value|
      if value.kind_of? Hash
        [:children, [:subsearch, key, value]]
      elsif key.kind_of? Array
        filter = value.kind_of?(Regexp) ?
          :parameterized_match : :parameterized_equality
        [key.first, [filter, *key, value]]
      else
        filter = value.kind_of?(Regexp) ?
          :match : :equality
        [key, [filter, key, value]]
      end
    end
    @filters << [:role, [:block_check]] if @block
  end

  ##
  # Checks if a candidate object is of the correct class, respecting
  # that that the class being searched for may not be defined yet.
  #
  # @param [AX::Element]
  def the_right_type? element
    unless @const
      if AX.const_defined? @klass
        @const = AX.const_get @klass
      else
        return false
      end
    end
    return element.kind_of? @const
  end

  ##
  # Determines if the element meets all the criteria of the filters,
  # spawning sub-searches if necessary.
  #
  # @param [AX::Element]
  def meets_criteria? element
    @filters.all? do |filter|
      if element.respond_to? filter.first
        self.send *filter.last, element
      end
    end
  end

  def subsearch klass, criteria, element
    !element.search(klass, criteria).blank?
  end

  def match attr, regexp, element
    element.attribute(attr).match regexp
  end

  def equality attr, value, element
    element.attribute(attr) == value
  end

  def parameterized_match attr, param, regexp, element
    element.attribute(attr, for_parameter: param).match regexp
  end

  def parameterized_equality attr, param, value, element
    element.attribute(attr, for_parameter: param) == value
  end

  def block_check element
    @block.call element
  end

end
