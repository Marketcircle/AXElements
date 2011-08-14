# -*- coding: utf-8 -*-

##
# Convenience methods to use when building an #inspect method for
# {AX::Element} and its descendants.
module Accessibility::PPInspector

  protected

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

    if    attributes.include? KAXTitleUIElementAttribute
      return ' ' + attribute(:title_ui_element).inspect
    elsif attributes.include? KAXDescriptionAttribute
      return ' ' + attribute(:description)
    elsif attributes.include? 'AXIdentifier'
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
    child_count = AX.attr_count_of_element @ref, KAXChildrenAttribute
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
