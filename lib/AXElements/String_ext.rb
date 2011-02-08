# Extensions to the String class.
class String

  # Returns the upper camel case version of the string. The string
  # is assumed to be in snake_case, but should return an unchanged
  # string if the string is already in camel case.
  #
  # I chose to make this method update the string in place as it
  # is a fairly hot method and should perform well; by running in
  # place we save an allocation (which is slow on MacRuby right now).
  # @return [String]
  def camelize!
    gsub! /(?:^|_)(.)/ do |match| match[-1].upcase end
  end

end
