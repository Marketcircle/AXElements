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
  attr_accessor :bye_button
  attr_accessor :scroll_area
  attr_accessor :menu
  attr_accessor :array_controller

  def applicationDidFinishLaunching(a_notification)
    add_accessibility_attributes
    populate_table
    set_identifiers
    populate_menu
  end

  def add_accessibility_attributes
    def window.accessibilityAttributeNames
      super + ['AXLol', 'AXPie', 'AXIsNyan', KAXURLAttribute, KAXDescriptionAttribute]
    end
    def window.accessibilityAttributeValue name
      case name
      when 'AXLol' then NSValue.valueWithRect(CGRectZero)
      when 'AXPie' then NSValue.valueWithRange(NSRange.new(10,10))
      when 'AXIsNyan' then false
      when KAXURLAttribute then NSURL.URLWithString('http://macruby.org/')
      when KAXDescriptionAttribute then 'Test Fixture'
      else super
      end
    end
  end

  def set_identifiers
    yes_button.setIdentifier  "I'm a little teapot"
    scroll_area.setIdentifier 'Text Area'
  end

  def post_notification sender
    NSAccessibilityPostNotification(yes_button.cell, 'Cheezburger')
    window.contentView.addSubview bye_button
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

  def remove_bye_button sender
    bye_button.removeFromSuperview
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
