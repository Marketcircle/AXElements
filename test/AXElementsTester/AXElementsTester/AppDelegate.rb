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
  attr_accessor :menu
  attr_accessor :array_controller

  def applicationDidFinishLaunching(a_notification)
    add_accessibility_attributes
    populate_table
    set_button_identifier
    populate_menu
  end

  def add_accessibility_attributes
    def window.accessibilityAttributeNames
      super + ['AXLol', 'AXIsNyan', KAXURLAttribute, KAXDescriptionAttribute]
    end
    def window.accessibilityAttributeValue name
      case name
      when 'AXLol' then NSValue.valueWithRect(CGRectZero)
      when 'AXIsNyan' then false
      when KAXURLAttribute then NSURL.URLWithString('http://macruby.org/')
      when KAXDescriptionAttribute then 'Test Fixture'
      else super
      end
    end
  end

  def set_button_identifier
    yes_button.setIdentifier "I'm a little teapot"
  end

  def post_notification sender
    NSAccessibilityPostNotification(yes_button.cell, 'Cheezburger')
  end

  def populate_table
    def array_controller.selectsInsertedObjects
      false
    end
    objects = window.accessibilityAttributeNames.map do |name|
      TableRow.new name, window.accessibilityAttributeValue(name).inspect
    end
    array_controller.addObjects objects
  end

  def populate_menu
    50.times do |num|
      item = NSMenuItem.alloc.initWithTitle num.to_s,
                                    action: nil,
                             keyEquivalent: ''
      menu.addItem item
    end
  end

  def orderFrontPreferencesPanel sender
    prefs = PrefPaneController.alloc.initWithWindowNibName 'PrefPane'
    prefs.loadWindow
    prefs.showWindow self
  end

end

class TableRow
  attr_accessor :name
  attr_accessor :value

  def initialize init_name, init_value
    @name, @value = init_name, init_value
  end
end
