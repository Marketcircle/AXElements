require 'accessibility/core'
require 'ax_elements/vendor/inflector'

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
  # @private
  #
  # Cached the constant value to avoid `#dup` call.
  #
  # @return [String]
  QUESTION_MARK = '?'.freeze

  ##
  # Try to mangle a method name to a singularized form. This will also
  # chomp off a '?' at the end of the symbol in cases of predicates.
  #
  # @param [Symbol]
  # @return [Symbol]
  def singularized sym
    sym.chomp(QUESTION_MARK).singularize.to_sym
  end
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
  # Used to test a symbol/string representing a method name.
  # Returns `true` if the string ends with a '?".
  def predicate?
    self[-1] == '?'
  end

  ##
  # Force the `#singularize` method to be defined on NSString objects,
  # and therefore on Symbol objects...at least until that bug gets
  # fixed.
  #
  # @return [String]
  def singularize
    Accessibility::Inflector.singularize(self)
  end

  ##
  # Force the `#underscore` method to be defined on NSString objects
  # so that it works on all strings.
  #
  # @return [String]
  def underscore
    Accessibility::Inflector.underscore(self)
  end

  ##
  # Returns the upper camel case version of the string. The string
  # is assumed to be in `snake_case`, but still works on a string that
  # is already in camel case.
  #
  # I have this method update the string in-place as it is a fairly hot
  # method and should perform well; by running in-place we save an
  # allocation (which is slow on MacRuby right now).
  #
  # Returns `nil` the string was empty.
  #
  # @return [String,nil] returns `self`
  def camelize
    gsub /(?:^|_)(.)/ do $1.upcase! || $1 end
  end
end


##
# Extensions to `CGPoint`.
class CGPoint
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

  ##
  # @note This method does not show up in the documentation with
  #       YARD 0.7.x
  #
  # @return [CGPoint]
  alias_method :to_point, :self

  @ax_value = KAXValueCGPointType
end


##
# Extensions to `NSObject`.
class NSObject
  ##
  # @note This method does not show up in the documentation with
  #       YARD 0.7.x
  #
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
# Correct a problem with ArgumentError not providing a proper backtrace.
#class Exception
#  alias_method :original_message, :message
#  def message
#    "#{original_message}\n\t#{backtrace.join("\n\t")}"
#  end
#end
