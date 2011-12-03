# -*- coding: utf-8 -*-

##
# Convenience methods to use when building an `#inspect` method for
# {AX::Element} and its descendants.
#
# The module only expects three methods in order to operate:
#
#  - `#attributes` returns a list of available attributes
#  - `#attribute` returns the value of a given attribute
#  - `#size_of` returns the size for an attribute
#
module Accessibility::PPInspector

  ##
  # @todo I feel a bit bad about having such a large method that has
  #       some inefficiencies.
  #
  # Create an identifier for `self` using various attributes that should
  # make it very easy to identify the element.
  #
  # @return [String]
  def pp_identifier
    # use or lack of use of #inspect is intentional for visual effect

    if attributes.include? KAXValueAttribute
      val = attribute :value
      if val.kind_of? NSString
        return " #{val.inspect}" unless val.empty?
      else
        # we assume that nil is not a legitimate value
        return " value=#{val.inspect}" unless val.nil?
      end
    end

    if attributes.include? KAXTitleAttribute
      val = attribute(:title)
      return " #{val.inspect}" if val && !val.empty?
    end

    if attributes.include? KAXTitleUIElementAttribute
      val = attribute :title_ui_element
      return BUFFER + val.inspect if val
    end

    if attributes.include? KAXDescriptionAttribute
      val = attribute(:description).to_s
      return BUFFER + val unless val.empty?
    end

    if attributes.include? KAXIdentifierAttribute
      return " id=#{attribute(:identifier)}"
    end

    # @todo should we have other fallbacks?
    return ::EMPTY_STRING
  end

  ##
  # Create a string that succinctly encodes the screen coordinates
  # of `self`.
  #
  # @return [String]
  def pp_position
    position = attribute :position
    if position
      " (#{position.x}, #{position.y})"
    else
      ::EMPTY_STRING
    end
  end

  ##
  # Create a string that nicely presents the number of children
  # that `self` has.
  #
  # @return [String]
  def pp_children
    child_count = size_of :children
    if child_count > 1
      " #{child_count} children"
    elsif child_count == 1
      ' 1 child'
    else # there are some odd edge cases
      ::EMPTY_STRING
    end
  end

  ##
  # Create a string that looks like a labeled check box. The label
  # is the given attribute, and the check box value will be
  # determined by the value of the attribute.
  #
  # @param [Symbol]
  # @return [String]
  def pp_checkbox attr
    " #{attr}[#{attribute(attr) ? '✔' : '✘'}]"
  end


  private

  ##
  # @private
  #
  # A string with a single space, used as a buffer. This is a
  # performance hack.
  #
  # @return [String]
  BUFFER = ' '.freeze

end
