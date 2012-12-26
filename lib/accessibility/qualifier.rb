# -*- coding: utf-8 -*-

require 'active_support/core_ext/object'
require 'accessibility/translator'

##
# Used in searches to answer whether or not a given element meets the
# expected criteria.
class Accessibility::Qualifier

  ##
  # Initialize a qualifier with the kind of object that you want to
  # qualify and a dictionary of filter criteria. You can optionally
  # pass a block if your qualification criteria is too complicated
  # for key/value pairs; the blocks return value will be used to
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
  # @param klass [#to_s]
  # @param criteria [Hash]
  # @yield Optional block that can qualify an element
  def initialize klass, criteria
    @klass    = TRANSLATOR.classify(klass)
    @criteria = criteria
    @block    = Proc.new if block_given?
    compile!
  end

  ##
  # Whether or not a candidate object matches the criteria given
  # at initialization.
  #
  # @param element [AX::Element]
  def qualifies? element
    the_right_type?(element) && meets_criteria?(element)
  end

  ##
  # Return a compact description of the qualifier. If the qualifier
  # includes a block then a checkmarked box will be included.
  #
  # @return [String]
  def describe
    "#{@klass}#{@criteria.ax_pp}#{@block ? '[✔]' : ''}"
  end


  private

  # @private
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

  ##
  # Take a hash of search filters and generate an optimized search
  # array. This is done to avoid checking types for each call to
  # {#qualifies?}.
  #
  # @param criteria [Hash]
  def compile!
    @filters = @criteria.map do |key, value|
      if value.kind_of? Hash
        [:subsearch, key, value]
      elsif key.kind_of? Array
        filter = value.kind_of?(Regexp) ?
          :parameterized_match : :parameterized_equality
        [filter, *key, value]
      else
        filter = value.kind_of?(Regexp) ?
          :match : :equality
        [filter, key, value]
      end
    end
    @filters << [:block_check] if @block
  end

  ##
  # Checks if a candidate object is of the correct class, respecting
  # that that the class being searched for may not be defined yet.
  #
  # @param element [AX::Element]
  def the_right_type? element
    unless @const
      if AX.const_defined? @klass
        @const = AX.const_get @klass
      else
        return false
      end
    end
    element.kind_of? @const
  end

  ##
  # Determines if the element meets all the criteria of the filters,
  # spawning sub-searches if necessary.
  #
  # @param element [AX::Element]
  def meets_criteria? element
    @filters.all? do |filter|
      self.send *filter, element
    end
  end

  def subsearch klass, criteria, element
    !element.search(klass, criteria).blank?
  end

  def match attr, regexp, element
    if element.attributes.include? attr
      element.attribute(attr).to_s.match regexp
    end
  end

  def equality attr, value, element
    if element.attributes.include? attr
      element.attribute(attr) == value
    end
  end

  def parameterized_match attr, param, regexp, element
    if element.parameterized_attributes.include? attr
      element.parameterized_attribute(attr, param).to_s.match regexp
    end
  end

  def parameterized_equality attr, param, value, element
    if element.parameterized_attributes.include? attr
      element.parameterized_attribute(attr, param) == value
    end
  end

  def block_check element
    @block.call element
  end

end


##
# AXElements extensions to `NSDictionary`.
class NSDictionary
  ##
  # Format the hash for AXElements pretty printing.
  #
  # @return [String]
  def ax_pp
    return '' if empty?

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
