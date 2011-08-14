##
# The UI element for radio buttons on the screen. No, I couldn't come up
# with anything useful for this docstring.
class AX::RadioButton < AX::Element

  ##
  # Overridden to support DWIM behavior.
  #
  # @return [Boolean]
  def == other
    return attribute(:title) == other if other.kind_of? NSString
    return super
  end

end
