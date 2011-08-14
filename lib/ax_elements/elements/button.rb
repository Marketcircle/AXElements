class AX::Button < AX::Element

  def == other
    return super unless other.kind_of? NSString
    return attribute(:title) == other
  end

end
