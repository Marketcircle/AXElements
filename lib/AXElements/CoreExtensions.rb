require 'active_support/inflector'

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

  alias_method :ax_array_method_missing, :method_missing
  ##
  # If the array contains {AX::Element} objects and the method name
  # belongs to an attribute then the method will be mapped
  # across the array. In this case, you can artificially pluralize
  # the attribute name and the lookup will singularize the method name
  # for you.
  #
  # Be careful when mapping actions as some actions could, in theory,
  # invalidate other elements in the array.
  #
  # You also have to be careful in cases where the array contains
  # various types of {AX::Element} objects that may not have the same
  # attributes or you could trigger a {NoMethodError}.
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
    method = method.to_s
    (method.predicate? ? method[0..-1] : method).singularize.to_sym
  end

end


##
# Extensions to the String class.
class NSMutableString

  ##
  # Returns the upper camel case version of the string. The string
  # is assumed to be in snake_case, but should return an unchanged
  # string if the string is already in camel case.
  #
  # I chose to make this method update the string in place as it
  # is a fairly hot method and should perform well; by running in
  # place we save an allocation (which is slow on MacRuby right now).
  # @return [String]
  def camelize!
    gsub! /(?:^|_)(.)/ do $1.upcase end
  end

  ##
  # Tells you if the symbol would be a predicate method by
  # checking if it ends with a question mark '?'.
  def predicate?
    match( /\?$/ ) != nil
  end

end


class CGPoint

  ##
  # Assumes the point represents something on the screen with the origin
  # in the bottom left and then translates the point to be in the same
  # place on screen if the origin were in the top left.
  #
  # This method will return nil if the co-ordinates cannot be translated.
  #
  # @param [CGPoint] point screen position in Cocoa screen coordinates
  # @return [CGPoint,nil]
  def carbonize!
    NSScreen.screens.each { |screen|
      if NSPointInRect(self, screen.frame)
        self.y = screen.frame.size.height - self.y
        return self
      end
    }
  end
  alias_method :carbon!,    :carbonize!
  alias_method :carbonify!, :carbonize!

  ##
  # Get the center point in a rectangle.
  #
  # @param [CGRect] rect
  # @return [CGPoint]
  def self.center_of_rect rect
    CGPoint.center rect.origin, rect.size
  end

  ##
  # Get in the center of a size with an origin.
  #
  # @param [CGPoint] origin
  # @param [CGSize] size
  # @return [CGPoint]
  def self.center origin, size
    x = origin.x + (size.width / 2)
    y = origin.y + (size.height / 2)
    CGPoint.new(x, y)
  end

end
