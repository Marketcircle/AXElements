require 'ax/element'

##
# Radio buttons are not the same as a generic button, radio buttons work
# in mutually exclusive groups (you can only select one at a time). You
# often have radio buttons when dealing with tab groups.
class AX::RadioButton < AX::Element

  ##
  # Test equality with another object. Equality can be with another
  # {AX::Element} or it can be with a string that matches the title
  # of the radio button.
  #
  # @return [Boolean]
  def == other
    return attribute(:title) == other if other.kind_of? NSString
    return super
  end

end
