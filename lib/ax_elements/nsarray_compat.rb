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
    smethod = TRANSLATOR.singularize(method.to_s.chomp('?'))
    map do |x|
      puts x.inspect
      if    !x.kind_of?(AX::Element) then super
      elsif  x.respond_to? method    then x.send method,  *args
      else                                x.send smethod, *args
      end
    end
  end


  private

  # @private
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

end

unless defined? NSArray
  NSArray = Array
end

##
# AXElements extensions for `NSArray`
class NSArray
  include Accessibility::NSArrayCompat

  if on_macruby?

    ##
    # Returns the tail of the array from `position`
    #
    # @example
    #
    #   [1, 2, 3, 4].from(0)   # => [1, 2, 3, 4]
    #   [1, 2, 3, 4].from(2)   # => [3, 4]
    #   [1, 2, 3, 4].from(10)  # => []
    #   [].from(0)             # => []
    #
    # @param position [Fixnum]
    # @return [Array]
    def from position
      self[position, length] || []
    end

    ##
    # Returns the beginning of the array up to `position`
    #
    #   [1, 2, 3, 4].to(0)   # => [1]
    #   [1, 2, 3, 4].to(2)   # => [1, 2, 3]
    #   [1, 2, 3, 4].to(10)  # => [1, 2, 3, 4]
    #   [].to(0)             # => []
    #
    # @param count [Fixnum]
    # @return [Array]
    def to count
      take count + 1
    end

    ##
    # Equal to `self[1]`
    def second
      at(1)
    end

    ##
    # Equal to `self[2]`
    def third
      at(2)
    end

    ##
    # Equal to `self[3]`
    def fourth
      at(3)
    end

    ##
    # Equal to `self[4]`
    def fifth
      at(4)
    end

    ##
    # Equal to `self[41]`
    #
    # Also known as accessing "the reddit".
    def forty_two
      at(41)
    end

  else

    ##
    # Create a new array with the same contents as the given array
    #
    # @param ary [Array]
    def arrayWithArray ary
      ary.dup
    end

  end

  alias_method :the_reddit, :forty_two

end
