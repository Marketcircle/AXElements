##
# Represents a search entity. Searches through a view hierarchy are
# breadth first.
class Accessibility::Search

  # @param [AX::Element] root the starting point of a search
  def initialize root
    @tree = Accessibility::Tree.new root
  end

  ##
  # Find all elements in the view hierarchy that match the given class
  # and the filter criteria.
  #
  # @param [Symbol,String] klass
  # @param [Hash] criteria
  # @return [Array<AX::Element>,Array<>]
  def find_all klass, criteria
    qualifier = Qualifier.new klass, criteria
    @tree.find_all { |element| qualifier.qualifies? element }
  end

  ##
  # Find the first element in the tree that has a certain type and
  # matches the filter criteria that has been specified.
  #
  # @param [Symbol,String] klass
  # @param [Hash] criteria
  # @return [AX::Element,nil]
  def find klass, criteria
    qualifier = Qualifier.new klass, criteria
    @tree.find { |element| qualifier.qualifies? element }
  end


  private

  ##
  # Create a search "block" to be used for element validation in a search.
  class Qualifier

    # @return [Symbol,String]
    attr_reader :sym

    # @return [Class]
    attr_reader :klass

    # @return [Hash]
    attr_reader :filters

    # @param [Symbol,String] target_klass
    # @param [Hash] filter_criteria
    def initialize target_klass, filter_criteria
      @sym     = target_klass
      @filters = filter_criteria
    end

    ##
    # Whether or not a candidate object matches the criteria given
    # at initialization.
    def qualifies? element
      return false unless the_right_type? element
      return false unless meets_criteria? element
      return true
    end


    private

    ##
    # Checks if a candidate object is of the correct class.
    #
    # This is an important method to optimize for search as it needs
    # to be called for each candidate object.
    def the_right_type? element
      return element.kind_of? klass if klass
      if AX.const_defined? sym
        klass = AX.const_get sym
        element.kind_of? klass
      else
        false
      end
    end

    # @return [Hash{Symbol=>Symbol}]
    TABLE = {
      title_ui_element: :value
    }

    ##
    # Determines if the element meets all the criteria of the filters
    # the Qualifier object was initialized with.
    def meets_criteria? element
      filters.all? do |filter, value|
        break false unless element.respond_to? filter
        filter_value = element.attribute filter
        if filter_value.class == value.class || filter_value.boolean?
          filter_value == value
        elsif filter_value.nil? || value.nil?
          false
        else
          filter_value.attribute(TABLE[filter]) == value
        end
      end
    end

  end

end
