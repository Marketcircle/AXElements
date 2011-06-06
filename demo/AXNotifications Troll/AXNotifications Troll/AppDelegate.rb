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
    notification = notification_for text_box.stringValue
    NSAccessibilityPostNotification(button.cell, notification)
    label.stringValue = "Posted '#{notification}' notification"
  end

  def applicationShouldTerminateAfterLastWindowClosed(the_application)
    true
  end


  private

  def notification_for string
    return Kernel.const_get(string) if Kernel.const_defined?(string)

    const = string.capitalize
    return Kernel.const_get(const) if Kernel.const_defined?(const)

    const = "KAX#{string}Notification"
    return Kernel.const_get(const) if Kernel.const_defined?(const)

    return string
  end

end

