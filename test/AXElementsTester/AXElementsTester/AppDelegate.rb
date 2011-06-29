#
#  AppDelegate.rb
#  AXElementsTester
#
#  Created by Mark Rada on 11-06-26.
#  Copyright 2011 Marketcircle Incorporated. All rights reserved.
#

class AppDelegate

  attr_accessor :window
  attr_accessor :yes_button

  def applicationDidFinishLaunching(a_notification)
    def window.accessibilityAttributeNames
      super + ['AXLol', 'AXIsNyan', KAXURLAttribute]
    end
    def window.accessibilityAttributeValue name
      case name
      when 'AXLol' then NSValue.valueWithRect(CGRectZero)
      when 'AXIsNyan' then false
      when KAXURLAttribute then NSURL.URLWithString('http://macruby.org/')
      else super
      end
    end
  end

  def post_notification sender
    NSAccessibilityPostNotification(yes_button.cell, 'Cheezburger')
  end

end
