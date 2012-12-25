require 'ax/element'
require 'accessibility/translator'
require 'active_support/core_ext/array/access'

##
# An old hack on arrays that allows you to map a single method across
# an array of {AX::Element} objects more succinctly than
# `Symbol#to_proc`.
#
# I've always been on the fence as to whether this was a good idea or
# not, but at this point there is too much code written that depends
# on this and so I will just keep it around for backwards compatability.
module Accessibility::NSArrayCompat

  ##
  # @note Debatably bad idea. Maintained for backwards compatibility.
  #
  # If the array contains {AX::Element} objects and the elements respond
  # to the method name then the method will be mapped across the array.
  # In this case, you can artificially pluralize the attribute name and
  # the lookup will singularize the method name for you.
  #
  # @example
  #
  #   rows   = outline.rows      # :rows is already an attribute # edge case
  #   fields = rows.text_fields  # you want the AX::TextField from each row
  #   fields.values              # grab the values
  #
  #   outline.rows.text_fields.values # all at once
  #
  def method_missing method, *args
    smethod = TRANSLATOR.singularize(method.chomp('?'))
    map do |x|
      if    !x.kind_of? AX::Element then super
      elsif  x.respond_to? method   then x.send method,  *args
      else                               x.send smethod, *args
      end
    end
  end


  private

  # @private
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

end


# AXElements extensions for `NSArray`.
class NSArray
  include Accessibility::NSArrayCompat
end
