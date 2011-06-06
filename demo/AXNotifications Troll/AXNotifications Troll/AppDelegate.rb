#
#  AppDelegate.rb
#  AXNotifications Troll
#
#  Created by Mark Rada on 11-06-05.
#  Copyright 2011 Marketcircle Incorporated. All rights reserved.
#

class AppDelegate

  attr_accessor :window
  attr_accessor :button
  attr_accessor :text_box
  attr_accessor :label

  def applicationDidFinishLaunching(a_notification)
    window.title = NSRunningApplication.currentApplication.bundleIdentifier
  end

  def send_notification(sender)
    NSAccessibilityPostNotification(button.cell, text_box.stringValue)
    label.stringValue = "Posted '#{text_box.stringValue}' notification"
  def applicationShouldTerminateAfterLastWindowClosed(the_application)
    true
  end

  end

end

