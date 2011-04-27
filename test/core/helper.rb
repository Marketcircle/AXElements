class TestCore < TestAX

  def spotlight_text_field
    screen    = NSScreen.mainScreen.frame
    spotlight = element_at_pos CGPoint.new(screen.size.width - 10, 5)
    skip 'Could not find spotlight in the menu bar' unless spotlight
    action_for spotlight, KAXPressAction
    group = children_for( children_for( children_for( spotlight ).first ).first )
    text_field = group.find do |element|
      attribute_for(element, KAXRoleAttribute) == KAXTextFieldRole
    end
    yield text_field
    action_for spotlight, KAXPressAction
  end

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
