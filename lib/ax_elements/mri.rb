unless on_macruby?

  KAXChildrenAttribute         = 'AXChildren'
  KAXRoleAttribute             = 'AXRole'
  KAXSubroleAttribute          = 'AXSubrole'
  KAXIdentifierAttribute       = 'AXIdentifier'
  KAXWindowCreatedNotification = 'AXWindowCreated'
  KAXMainWindowAttribute       = 'AXMainWindow'
  KAXFocusedAttribute          = 'AXFocused'
  KAXValueChangedNotification  = 'AXValueChanged'
  KAXTitleAttribute            = 'AXTitle'
  KAXURLAttribute              = 'AXURL'
  KAXTitleUIElementAttribute   = 'AXTitleUIElement'
  KAXPlaceholderValueAttribute = 'AXPlaceholderValue'
  KAXWindowRole                = 'AXWindow'
  KAXCloseButtonSubrole        = 'AXCloseButton'
  KAXTrashDockItemSubrole      = 'AXTrashDockItem'
  KAXRTFForRangeParameterizedAttribute    = 'AXRTFForRange'
  KAXIsApplicationRunningAttribute        = 'AXIsApplicationRunning'
  KAXStringForRangeParameterizedAttribute = 'AXStringForRange'

  unless defined? NSString
    NSString = String
  end

  unless defined? NSDictionary
    NSDictionary = Hash
  end

  unless defined? NSArray
    NSArray = Array
  end

  unless defined? NSDate
    NSDate = Time
  end

  class Symbol

    def chomp suffix
      to_s.chomp suffix
    end

  end

end

unless defined? KAXIdentifierAttribute
  ##
  # Added for backwards compatability with Snow Leopard.
  # This attribute is standard with Lion and newer. AXElements depends
  # on it being defined.
  #
  # @return [String]
  KAXIdentifierAttribute = 'AXIdentifier'
end

