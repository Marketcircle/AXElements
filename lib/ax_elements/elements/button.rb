##
# A generic push button and the base class for most, but not all
# other buttons, including close buttons and sort buttons, but
# not including pop-up buttons or radio buttons.
class AX::Button < AX::Element

  ##
  # Test equality with another object. Equality can be with another
  # {AX::Element} or it can be with a string that matches the title
  # of the button.
  #
  # @return [Boolean]
  def == other
    return super unless other.kind_of? NSString
    return attribute(:title) == other
  end

end
