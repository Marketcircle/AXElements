class TestCore < TestAX

  def set_attribute_for element, attribute, value
    AXUIElementSetAttributeValue( element, attribute, value )
  end

  # turn logging on bet
  def with_logging level = Logger::DEBUG
    original_level = AX.log.level
    AX.log.level   = level
    yield
    AX.log.level   = original_level
  end

end
