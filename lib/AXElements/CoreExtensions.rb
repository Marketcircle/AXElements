require 'active_support/core_ext/array/access'
require 'active_support/inflector'

##
# Overrides for the Array class that makes it possible to
module ArrayAXElementExtensions

  ##
  # If the array contains {AX::Element} objects and the method name
  # belongs to an attribute or action then the method will be mapped
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
    return super                 if empty? || !(first.kind_of?(AX::Element))
    return map(&method)          if first.respond_to?(method)
    singular_method              =  singularized_method_name(method)
    return map(&singular_method) if first.respond_to?(singular_method)
    super
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


# Monkey patches on top of Array
class NSArray
  include ArrayAXElementExtensions
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
