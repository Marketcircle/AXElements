# This file contains all the monkey patches used in AXElements

# Extensions to the String class.
class String

  # @todo benchmark against the #split.#capitalize.#join technique
  # Returns the upper camel case version of the string. The string
  # is assumed to be in snake_case.
  # @return [String]
  def camelize!
    self.gsub!(/(?:^|_)(.)/) { $1.upcase }
  end
end
