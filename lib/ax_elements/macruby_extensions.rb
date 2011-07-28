require 'active_support/inflector'

##
# Extensions to NSArray.
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
  # Create a CGPoint from the first two elements in the array.
  #
  # @return [CGPoint]
  def to_point
    CGPoint.new(first, second)
  end

  ##
  # Create a CGSize from the first two elements in the array.
  #
  # @return [CGSize]
  def to_size
    CGSize.new(first, second)
  end

  ##
  # Create a CGRect from the first four elements in the array.
  #
  # @return [CGRect]
  def to_rect
    CGRectMake(*self[0,4])
  end

  ##
  # @method blank?
  #
  # Borrowed from Active Support.
  alias_method :blank?, :empty?

  alias_method :ax_array_method_missing, :method_missing
  ##
  # If the array contains {AX::Element} objects and the method name
  # belongs to an attribute then the method will be mapped
  # across the array. In this case, you can artificially pluralize
  # the attribute name and the lookup will singularize the method name
  # for you.
  #
  # You also have to be careful in cases where the array contains
  # various types of {AX::Element} objects that may not all respond to
  # the same attribute.
  def method_missing method, *args
    if first.kind_of?(AX::Element)
      return map(&method) if first.respond_to?(method)
      return map(&singularized_method_name(method))
    end
    ax_array_method_missing(method, *args)
  end


  private

  ##
  # Takes a method name and singularizes it, including the case where
  # the method name is a predicate.
  #
  # @param [Symbol] method
  # @return [Symbol]
  def singularized_method_name method
    (method.predicate? ? method[0..-2] : method).singularize.to_sym
  end
end


##
# Extensions to NSMutableString
class NSMutableString
  ##
  # Returns the upper camel case version of the string. The string
  # is assumed to be in snake_case, but still works on a string that
  # is already in camel case.
  #
  # I chose to make this method update the string in place as it
  # is a fairly hot method and should perform well; by running in
  # place we save an allocation (which is slow on MacRuby right now).
  #
  # Returns nil the string was empty.
  #
  # @return [String,nil] returns `self`
  def camelize!
    gsub! /(?:^|_)(.)/ do $1.upcase end
  end
end


##
# Extensions to NSString
class NSString
  ##
  # Used to test a symbol/string representing a method name.
  # Returns `true` if the string ends with a '?".
  def predicate?
    self[-1] == '?'
  end

  ##
  # Force the #singularize method to be defined on NSString objects,
  # and therefore on Symbol objects...at least until that bug gets
  # fixed.
  #
  # @return [String]
  def singularize
    ActiveSupport::Inflector.singularize(self)
  end
end


##
# Extensions to CGPoint
class CGPoint
  ##
  # Get the center point in a rectangle.
  #
  # @param [CGRect] rect
  # @return [CGPoint]
  def self.center_of_rect rect
    rect.origin.center rect.size
  end

  ##
  # Given the origin and size of a rectangle, find the center of
  # the rectangle with co-ordinates relative to the screen origin.
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

  @ax_value = KAXValueCGPointType
end


##
# Extensions to Boxed objects.
class Boxed
  class << self
    # @return [AXValueType]
    attr_reader :ax_value
  end

  ##
  # Create an AXValue from the Boxed instance. This will only
  # work if for a few boxed types, check the AXAPI documentation.
  #
  # @return [AXValueRef]
  def to_axvalue
    klass = self.class
    ptr = Pointer.new klass.type
    ptr.assign self
    AXValueCreate(klass.ax_value, ptr)
  end
end


##
# Extensions to CGSize.
class CGSize
  @ax_value = KAXValueCGSizeType
end


##
# Extensions to CGRect.
class CGRect
  @ax_value = KAXValueCGRectType
end


##
# Extensions to CFRange.
class CFRange
  @ax_value = KAXValueCFRangeType
end


##
# Extensions for searching.
class NilClass
  ##
  # Borrowed from Active Support.
  def blank?
    true
  end
end


# ##
# # Correct a problem with ArgumentError not providing a proper backtrace.
# class ArgumentError
#   alias_method :original_message, :message
#   def message
#     "#{original_message}\n\t#{backtrace.join("\n\t")}"
#   end
# end


# ##
# # Correct a problem with ArgumentError not providing a proper backtrace.
# class NameError
#   alias_method :original_message, :message
#   def message
#     "#{original_message}\n\t#{backtrace.join("\n\t")}"
#   end
# end
