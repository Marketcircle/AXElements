##
# Usually a label or something...
class AX::StaticText < AX::Element

  ##
  # Overridden in order to provide slightly different semantics.
  #
  # @return [Boolean]
  def == other
    return super unless other.kind_of? NSString
    return attribute(:value) == other
  end

end
