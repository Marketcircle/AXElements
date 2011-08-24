# -*- coding: utf-8 -*-

##
# Convenience methods to use when building an #inspect method for
# {AX::Element} and its descendants.
module Accessibility::PPInspector


  protected

  ##
  # Added for backwards compatability with Snow Leopard.
  #
  # @return [String]
  KAXIdentifierAttribute = 'AXIdentifier'

  ##
  # Create an identifier for {#inspect} that should make it very
  # easy to identify the element.
  #
  # @return [String]
  def pp_identifier
    if attributes.include? KAXValueAttribute
      val = attribute :value
      if val.kind_of? NSString
        return " #{val.inspect}" unless val.empty?
      else
        return " value=#{val.inspect}"
      end
    end

    if attributes.include? KAXTitleAttribute
      val = attribute(:title)
      return " #{val.inspect}" if val && !val.empty?
    end

    if attributes.include? KAXTitleUIElementAttribute
      val = attribute :title_ui_element
      return ' ' + val.inspect if val
    end

    if attributes.include? KAXDescriptionAttribute
      val = attribute(:description).to_s
      return ' ' + val unless val.empty?
    end

    if attributes.include? KAXIdentifierAttribute
      return " id=#{attribute(:identifier)}"
    end

    # @todo should we have other fallbacks?
    return NSString.string
  end

  ##
  # Nicely encoded position of `self`.
  #
  # @return [String]
  def pp_position
    position = attribute :position
    " (#{position.x}, #{position.y})"
  end

  ##
  # String with number of children that `self` has.
  #
  # @return [String]
  def pp_children
    child_count = size_of :children
    if child_count > 1
      " #{child_count} children"
    elsif child_count == 1
      ' 1 child'
    else
      NSString.string
    end
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
