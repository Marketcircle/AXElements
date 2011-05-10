class TestCore < TestAX

  def set_attribute_for element, attribute, value
    AXUIElementSetAttributeValue( element, attribute, value )
  end

end
