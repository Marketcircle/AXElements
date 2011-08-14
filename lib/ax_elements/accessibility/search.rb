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

    # @param [Symbol,String] target
    # @param [Hash] filters
    def initialize target, filters
      @sym     = target
      @filters = filters
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
    # Checks if a candidate object is of the correct class.
    #
    # This is an important method to optimize for search.
    #
    # @param [AX::Element] element
    def the_right_type? element
      return element.kind_of? @klass if @klass
      if AX.const_defined? @sym
        @klass = AX.const_get @sym
        return element.kind_of? @klass
      else
        return false
      end
    end

    ##
    # @todo How could we handle filters that use parameterized
    #       attributes?
    #
    # Determines if the element meets all the criteria of the filters.
    #
    # @param [AX::Element] element
    def meets_criteria? element
      @filters.all? do |filter, value|
        if element.respond_to? filter
          element.send(filter) == value
        elsif element.respond_to? :children
          !element.search(filter, value).blank?
        else # this legitimately occurs
          false
        end
      end
    end
  end

end
