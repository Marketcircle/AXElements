##
# @todo Search does not handle if the object does not respond to a
#       filter. Though, this is implicitly a low risk scenario.
#
# Represents a search entity. Searches through a view hierarchy are
# breadth first.
class Accessibility::Search

  # @param [AX::Element] root the starting point of a search
  def initialize root
    root.attributes.include?(KAXChildrenAttribute) ?
      (@tree = Accessibility::Tree.new(root)) :
      raise(ArgumentError, "Can't search #{root.inspect} as it has no children")
  end

  ##
  # Find all elements in the view hierarchy that match the given class
  # and any other search criteria.
  #
  # @param [Symbol,String] target_klass
  # @param [Hash] criteria
  # @return [Array<AX::Element>,Array<>]
  def find_all klass, criteria
    @tree.find_all &Qualifier.new(klass, criteria).method(:qualifies?)
  end

  ##
  # Find the first element in the tree that has a certain type and
  # matches any other criteria that has been specified.
  #
  # @param [Symbol,String] target_klass
  # @param [Hash] criteria
  # @return [AX::Element,nil]
  def find klass, criteria
    @tree.find &Qualifier.new(klass, criteria).method(:qualifies?)
  end


  private

  ##
  # Create a search "block" to be used for element validation in a search.
  class Qualifier

    # @return [Symbol,String]
    attr_reader :klass_sym

    # @return [Class]
    attr_accessor :klass

    # @return [Hash]
    attr_reader :filters

    # @param [Symbol,String] target_klass
    # @param [Hash] filter_criteria
    def initialize target_klass, filter_criteria
      @klass_sym = target_klass
      @filters   = filter_criteria
    end

    ##
    # Whether or not a candidate object matches the criteria given
    # at initialization.
    def qualifies? element
      return false unless the_right_type?(element)
      return false if filters.find do |filter, value|
        break true unless element.respond_to?(filter)
        filter_value = element.get_attribute(filter)
        if filter_value.class == value.class
          filter_value != value
        else
          filter_value.attribute(TABLE[filter]) != value
        end
      end
      return true
    end


    private

    ##
    # @todo Consider not looking up classes, and instead, just comparing
    #       the #role of the candidate object with the #klass_sym that
    #       was given. Is the price of doing const lookups more than
    #       just doing string comparisons all the time? What is the
    #       threshold?
    #
    # Checks if a candidate object is of the correct class.
    #
    # This is an important method to optimize for search as it needs
    # to be called for each candidate object.
    def the_right_type? element
      return element.is_a?(klass) if klass
      AX.const_defined?(klass_sym) ?
        element.is_a?(klass = AX.const_get(klass_sym)) : false
    end

    # @return [Hash{Symbol=>String}]
    TABLE = {
      title_ui_element: KAXValueAttribute
    }

  end

end
