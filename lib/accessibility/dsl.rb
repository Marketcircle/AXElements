# -*- coding: utf-8 -*-

require 'mouse'
require 'ax/element'
require 'ax/systemwide'
require 'accessibility'

##
# @todo Allow the animation duration to be overridden for Mouse stuff?
#
# DSL methods for AXElements.
#
# The idea here is to pull actions out from an object and put them
# in front of object to give AXElements more of a DSL feel to make
# communicating test steps more clear. See the
# {file:docs/Acting.markdown Acting tutorial} for examples on how to use
# methods from this module.
module Accessibility::DSL


  # @group Actions

  ##
  # We assume that any method that has the first argument with a type
  # of {AX::Element} is intended to be an action and so `#method_missing`
  # will forward the message to the element.
  #
  # @param [String] method an action constant
  def method_missing method, *args
    arg = args.first
    if arg.kind_of?(AX::Element) && arg.actions.include?(method)
      return arg.perform method
    end
    # should be able to just call super, but there is a bug in MacRuby (#1320)
    # so we just recreate what should be happening
    message = "undefined method `#{method}' for #{self}:#{self.class}"
    raise NoMethodError, message, caller(1)
  end

  ##
  # Try to perform the `press` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def press element
    element.perform :press
  end

  ##
  # Try to perform the `show_menu` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def show_menu element
    element.perform :show_menu
  end

  ##
  # Try to perform the `pick` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def pick element
    element.perform :pick
  end

  ##
  # Try to perform the `decrement` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def decrement element
    element.perform :decrement
  end

  ##
  # Try to perform the `confirm` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def confirm element
    element.perform :confirm
  end

  ##
  # Try to perform the `increment` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def increment element
    element.perform :increment
  end

  ##
  # Try to perform the `delete` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def delete element
    element.perform :delete
  end

  ##
  # Try to perform the `cancel` action on the given element.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def cancel element
    element.perform :cancel
  end

  ##
  # Tell an app to hide itself.
  #
  # @param [AX::Application]
  # @return [Boolean]
  def hide app
    app.perform :hide
  end

  ##
  # Tell an app to unhide itself. This does not guarantee it will be
  # focused.
  #
  # @param [AX::Application]
  # @return [Boolean]
  def unhide app
    app.perform :unhide
  end
  alias_method :show, :unhide

  ##
  # Tell an app to quit.
  #
  # @param [AX::Application]
  # @return [Boolean]
  def terminate app
    app.perform :terminate
  end

  ##
  # Find the app with the given option.
  #
  # @example
  #
  #   app_with identifier: 'com.apple.finder'
  #   app_with name: 'Finder'
  #   app_with pid: 35843
  #
  # @param [Hash{Symbol=>Object}] opt
  # @option opt [Symbol] :bundle_identifier
  # @option opt [Symbol] :identifier
  # @option opt [Symbol] :bundle_id
  # @option opt [Symbol] :id
  # @option opt [Symbol] :name
  # @option opt [Symbol] :process_identifier
  # @option opt [Symbol] :pid
  # @return [AX::Application]
  def app_with opt
    value = opt.values.first
    case opt.keys.first
    when :bundle_identifier, :bundle_id, :identifier, :id
      Accessibility.application_with_bundle_identifier value
    when :name
      Accessibility.application_with_name value
    when :process_identifier, :pid
      Accessibility.application_with_pid value
    else
      raise ArgumentError, "#{key.inspect} is not a valid option"
    end
  end
  alias_method :launch, :app_with

  ##
  # @note This method overrides `Kernel#raise` so we have to check the
  #       class of the first argument to decide which code path to take.
  #
  # Try to perform the `raise` action on the given element.
  #
  # @overload raise element
  #   @param [AX::Element] element
  #   @return [Boolean]
  #
  # @overload raise exception[, message[, backtrace]]
  #   The normal way to raise an exception.
  def raise *args
    arg = args.first
    arg.kind_of?(AX::Element) ? arg.perform(:raise) : super
  end

  ##
  # Focus an element on the screen, but do not set focus again if
  # already focused.
  #
  # @param [AX::Element]
  def set_focus element
    element.set(:focused, to: true) if element.respond_to? :focused?
  end

  ##
  # @todo Handle parameterized attributes
  #
  # @note We try to set focus to the element first; this is to avoid false
  #       positives where developers assumed an element would have to have
  #       focus before a user could change the value.
  #
  # Set the value of an attribute on an element.
  #
  # You would think that the `#set` method should belong to {AX::Element},
  # but I think taking it out of the class and putting it in front helps
  # make the difference between performing actions and inspecting UI more
  # concrete.
  #
  # @overload set element, attribute_name: new_value
  #   Set a specified attribute to a new value
  #   @param [AX::Element] element
  #   @param [Hash{attribute_name=>new_value}] change
  #
  # @overload set element, new_value
  #   Set the `value` attribute to a new value
  #   @param [AX::Element] element
  #   @param [Object] change
  #
  # @return [nil] do not rely on a return value
  def set element, change
    if element.respond_to? :focused
      if element.writable_attribute? :focused
        set_focus element
      end
    end

    key, value = change.is_a?(Hash) ? change.first : [:value, change]
    element.set key, to: value
  end

  ##
  # Simulate keyboard input by typing out the given string. To learn
  # more about how to encode modifier keys (e.g. Command), see the
  # dedicated documentation page on
  # {file:docs/KeyboardEvents.markdown Keyboard Events}.
  #
  # @overload type string
  #   Send input to the currently focused application
  #   @param [#to_s]
  #
  # @overload type string, app
  #   Send input to a specific application
  #   @param [#to_s]
  #   @param [AX::Application]
  def type string, app = AX::SystemWide.new
    app.type_string string.to_s
  end


  # @group Notifications

  ##
  # Register for a notification from a specific element.
  #
  # @param [#to_s]
  # @param [Array(#to_s,AX::Element)]
  def register_for notif, from: element, &block
    @registered_elements ||= []
    @registered_elements << element
    element.on_notification notif, &block
  end

  ##
  # @deprecated This API exists for backwards compatability only
  #
  # Register for a notification from a specific element.
  #
  # @param [AX::Element]
  # @param [String]
  def register_for_notification element, notif, &block
    register_for notif, from: element, &block
  end

  ##
  # Pause script execution until notification that has been registered
  # for is received or the full timeout period has passed.
  #
  # If the script is unpaused because of a timeout, then it is assumed
  # that the notification was never received and all notification
  # registrations will be unregistered to avoid future complications.
  #
  # @param [Float] timeout number of seconds to wait for a notification
  # @return [Boolean]
  def wait_for_notification timeout = 10.0
    # We use RunInMode because it has timeout functionality
    case CFRunLoopRunInMode(KCFRunLoopDefaultMode, timeout, false)
    when KCFRunLoopRunStopped       then true
    when KCFRunLoopRunTimedOut      then false.tap { |_| unregister_notifications }
    when KCFRunLoopFinished         then
      raise RuntimeError, 'The run loop was not configured properly'
    when KCFRunLoopRunHandledSource then
      raise RuntimeError, 'Did you start your own run loop?'
    else
      raise 'You just found a bug, might be yours, or OS X, or MacRuby...'
    end
  end

  ##
  # Undo _all_ notification registries.
  def unregister_notifications
    @registered_elements.each do |element|
      element.unregister_notifications
    end
    @registered_elements = []
  end

  ##
  # @note This has not been thoroughly tested yet, in some cases it may
  #       cause MacRuby to crash.
  #
  # Simply wait around for something to show up. This method takes a block
  # which should give the path for an element that will eventually exist,
  # or possibly already exists when you call this method. This method works
  # by polling until the element appears or a timeout occurs.
  #
  # This is an alternative to using the notifications system. It is far
  # easier to use than notifications in most cases, but it will perform
  # more slowly.
  #
  # @example
  #
  #   # Waiting for a hypothetical email from Mark Rada to appear
  #   wait_for(5) { mail.main_window.static_text(value: 'Mark Rada') }
  #
  #   # Waiting for a dialog window to show up
  #   wait_for { app.dialog }
  #
  # @param [Number]
  # @yield
  # @return [AX::Element]
  def wait_for timeout = 30
    start ||= Time.now
    yield
  rescue Accessibility::SearchFailure, RuntimeError => e
    raise e unless e.message.match /system failure/
    raise e if (Time.now - start) > timeout
    sleep 0.25 && retry
  end


  # @group Mouse Input

  ##
  # @overload move_mouse_to(element)
  #   Move the mouse to a UI element
  #   @param [AX::Element]
  #
  # @overload move_mouse_to(point)
  #   Move the mouse to an arbitrary point
  #   @param [CGPoint]
  #
  # @overload move_mouse_to([x,y])
  #   Move the mouse to an arbitrary point given as an two element array
  #   @param [Array(Float,Float)]
  def move_mouse_to arg
    Mouse.move_to arg.to_point
  end

  ##
  # There are many reasons why you would want to cause a drag event
  # with the mouse. Perhaps you want to drag an object to another
  # place, or maybe you want to hightlight an area of the screen.
  #
  # This method will drag the mouse from its current point on the screen
  # to the point given by calling `#to_point` on the argument.
  #
  # Generally, you will pass a {CGPoint} or some kind of {AX::Element},
  # but you could pass anything that responds to `#to_point`.
  #
  # @param [#to_point]
  def drag_mouse_to arg
    Mouse.drag_to arg.to_point
  end

  ##
  # @todo Need to expose the units option? Would allow scrolling by pixel.
  #
  # Scrolls an arbitrary number of lines at the mouses current point on
  # the screen. Use a positive number to scroll down, and a negative number
  # to scroll up.
  #
  # If the second argument is provided then the mouse will move to that
  # point first; the argument must respond to `#to_point`.
  #
  # @param [Number]
  # @param [#to_point]
  def scroll lines, obj = nil
    move_mouse_to obj if obj
    Mouse.scroll lines
  end

  ##
  # Perform a regular click.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param [#to_point]
  def click obj = nil
    move_mouse_to obj if obj
    Mouse.click
  end

  ##
  # Perform a right (aka secondary) click action.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param [#to_point]
  def right_click obj = nil
    move_mouse_to obj if obj
    Mouse.right_click
  end
  alias_method :secondary_click, :right_click

  ##
  # Perform a double click action.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param [#to_point]
  def double_click obj = nil
    move_mouse_to obj if obj
    Mouse.double_click
  end


  # @group Macros

  ##
  # Show the "About" window for an app.
  #
  # @param [AX::Application]
  # @return [AX::Window]
  def show_about_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title: "About #{app.title}")
    app.dialog
  end

  ##
  # Try to open the preferences for an app using the menu bar.
  #
  # @param [AX::Application]
  # @return [AX::Window]
  def show_preferences_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title:'Preferences…')
    app.dialog
  end

  ##
  # @todo Scroll horizontally.
  #
  # Scroll though a table until the given element is visible.
  #
  # If you need to scroll an unknown ammount of units through a scroll area
  # you can just pass the element that you need visible and this method
  # will scroll to it for you.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def scroll_to element
    scroll_area = element.ancestor :scroll_area

    return if NSContainsRect(scroll_area.bounds, element.bounds)
    move_mouse_to scroll_area
    # calculate direction to scroll
    direction = element.position.y > scroll_area.position.y ? -5 : 5
    until NSContainsRect(scroll_area.bounds, element.bounds)
      scroll direction
    end
  end

  ##
  # Scroll a popup menu to an item in the menu and then move the
  # mouse pointer to that item.
  #
  # @param [AX::Element]
  # @return [Boolean]
  def scroll_menu_to element
    menu = element.ancestor :menu

    return if NSContainsRect(menu.bounds, element.bounds)
    move_mouse_to menu

    direction = element.position.y > menu.position.y ? -5 : 5
    until NSContainsRect(menu.bounds, element.bounds)
      scroll direction
    end

    until Accessibility.element_under_mouse == element
      move_mouse_to element
      sleep 0.2
    end
  end

end
