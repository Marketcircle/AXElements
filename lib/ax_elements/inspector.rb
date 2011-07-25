# -*- coding: utf-8 -*-

##
# Convenience methods to use when building an #inspect method for
# {AX::Element} and its descendants.
module Accessibility::Inspector

  protected

  ##
  # Create an identifier for {#inspect} that should make it very
  # easy to identify the element. Ironically, we do not use the
  # AXIdentifier attribute available in Lion.
  #
  # @return [String]
  def pp_identifier
    if attributes.include? KAXValueAttribute
      " value=#{attribute(:value).inspect}"
    elsif attributes.include? KAXTitleAttribute
      " #{attribute(:title).inspect}"
    elsif attributes.include? 'AXIdentifier'
      " id=#{attribute(:identifier)}"
    else # @todo should we have other fallbacks?
      ''
    end
  end

  ##
  # Nicely encoded position of `self`.
  #
  # @return [String]
  def pp_position
    position = attribute(:position)
    " (#{position.x}, #{position.y})"
  end

  ##
  # String with number of children that `self` has.
  #
  # @return [String]
  def pp_children
    child_count = AX.attr_count_of_element(@ref, KAXChildrenAttribute)
    " #{child_count} #{child_count == 1 ? 'child' : 'children'}"
  end

  ##
  # Create a string where the argument is looked up as an attribute
  # of `self` and the boolean value returned is represented by
  # a checkbox.
  #
  # @param [Symbol] value
  # @return [String]
  def pp_checkbox value
    " #{value}[#{attribute(value) ? '✔' : '✘'}]"
  end

end
