require 'accessibility/core'
require 'accessibility/translator'

##
# Extensions to `NSArray`.
class NSArray
  ##
  # Equivalent to `#[1]`
  def second
    at(1)
  end

  ##
  # Equivalent to `#[2]`
  def third
    at(2)
  end

  ##
  # Create a `CGPoint` from the first two elements in the array.
  #
  # @return [CGPoint]
  def to_point
    CGPoint.new(first, second)
  end

  ##
  # Create a `CGSize` from the first two elements in the array.
  #
  # @return [CGSize]
  def to_size
    CGSize.new(first, second)
  end

  ##
  # Create a `CGRect` from the first four elements in the array.
  #
  # @return [CGRect]
  def to_rect
    CGRectMake(*self[0,4])
  end

  ##
  # @method blank?
  #
  # Borrowed from ActiveSupport. Too bad this docstring isn't being
  # picked up by YARD.
  alias_method :blank?, :empty?

  alias_method :nsarray_method_missing, :method_missing
  ##
  # If the array contains {AX::Element} objects and the elements respond
  # to the method name then the method will be mapped across the array.
  # In this case, you can artificially pluralize the attribute name and
  # the lookup will singularize the method name for you.
  #
  # @example
  #
  #   rows   = outline.rows      # :rows is already an attribute
  #   fields = rows.text_fields  # you want the AX::TextField from each row
  #   fields.values              # grab the values
  #
  #   outline.rows.text_fields.values # all at once
  #
  def method_missing method, *args
    map do |x|
      nsarray_method_missing method, *args unless x.kind_of? AX::Element
      meth = x.respond_to?(method) ? method : singularized(method)
      x.send meth, *args
    end
  end


  private

  ##
  # Try to mangle a method name to a singularized form. This will also
  # chomp off a '?' at the end of the symbol in cases of predicates.
  #
  # @param [Symbol]
  # @return [Symbol]
  def singularized sym
    TRANSLATOR.singularize(sym.chomp('?'))
  end

  # @private
  TRANSLATOR = Accessibility::Translator.instance
end


##
# @private
#
# An empty string, performance hack since using it means you do not
# have to allocate new empty strings.
#
# @return [String]
EMPTY_STRING = ''.freeze

##
# Extensions to `NSString`.
class NSString
  ##
  # @method blank?
  alias_method :blank?, :empty?
end


##
# Extensions to `NSObject`.
class NSObject
  # @return [Object]
  alias_method :to_axvalue, :self
end


##
# Extensions to `Boxed` objects. `Boxed` is the superclass for all structs
# that MacRuby brings over using its BridgeSupport.
class Boxed
  include Accessibility::Core

  class << self
    ##
    # The `AXValue` constant for the struct type. Not all structs
    # have a value.
    #
    # @return [AXValueType]
    attr_reader :ax_value
  end

  ##
  # Create an `AXValue` from the `Boxed` instance. This will only
  # work if for a few boxed types, you will need to check the AXAPI
  # documentation for an up to date list.
  #
  # @return [AXValueRef]
  def to_axvalue
    wrap self
  end


  private

  ##
  # Return the height of the main screen.
  #
  # @return [Float]
  def screen_height
    NSMaxY(NSScreen.mainScreen.frame)
  end
end


##
# Extensions to `CGPoint`.
class CGPoint
  @ax_value = KAXValueCGPointType

  ##
  # Find the center of a rectangle, treating `self` as the origin and
  # the given `size` as the size of the rectangle.
  #
  # @param [CGSize] size
  # @return [CGPoint]
  def center size
    x = self.x + (size.width / 2.0)
    y = self.y + (size.height / 2.0)
    CGPoint.new(x, y)
  end

  # @return [CGPoint]
  alias_method :to_point, :self

  ##
  # Treats the point as belonging to the flipped co-ordinate system
  # and then flips it to be using the Cartesian co-ordinate system.
  #
  # @return [CGPoint]
  def flip!
    self.y = screen_height - self.y
    self
  end
end


##
# Extensions to `CGSize`.
class CGSize
  @ax_value = KAXValueCGSizeType
end


##
# Extensions to `CGRect`.
class CGRect
  @ax_value = KAXValueCGRectType

  ##
  # Treats the rect as belonging to the flipped co-ordinate system
  # and then flips it to be using the Cartesian co-ordinate system.
  #
  # @return [CGRect]
  def flip!
    origin.y = screen_height - NSMaxY(self)
    self
  end
end


##
# Extensions to `CFRange`.
class CFRange
  @ax_value = KAXValueCFRangeType
end


##
# Extensions to `NilClass`.
class NilClass
  ##
  # Borrowed from Active Support.
  def blank?
    true
  end
end


##
# Workaround for MacRuby ticket #1334
class Exception
  alias_method :original_message, :message
  def message
    "#{original_message}\n\t#{backtrace.join("\n\t")}"
  end
end
