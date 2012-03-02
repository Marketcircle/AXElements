# -*- coding: utf-8 -*-

require 'mouse'
require 'ax/element'
require 'ax/application'
require 'ax/systemwide'
require 'accessibility'
require 'accessibility/debug'

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
  # Find the application with the given bundle identifier.
  # If the application is not already running, it will be
  # launched.
  #
  # @example
  #
  #   app_with_identifier 'com.apple.finder'
  #
  # @param [String]
  # @return [AX::Application]
  def app_with_bundle_identifier id
    Accessibility.application_with_bundle_identifier id
  end
  alias_method :app_with_bundle_id, :app_with_bundle_identifier
  alias_method :launch,             :app_with_bundle_identifier

  ##
  # Find the application with the given name.
  #
  # @example
  #
  #   app_with_name 'Finder'
  #
  # @param [String]
  # @return [AX::Application,nil]
  def app_with_name name
    Accessibility.application_with_name name
  end

  ##
  # Find the application with the given process identifier.
  #
  # @example
  #
  #   app_with_pid 35843
  #
  # @param [Fixnum]
  # @return [AX::Application]
  def app_with_pid pid
    Accessibility.application_with_pid pid
  end

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
  # Focus an element on the screen if it can be focused. It is safe to
  # pass any element into this method as nothing will happen if it is
  # not capable of having focus set on it.
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
  def type string, app = system_wide
    sleep 0.1
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
    return unless @registered_elements
    @registered_elements.each do |element|
      element.unregister_notifications
    end
    @registered_elements = []
  end

  ##
  # @todo Perhaps this method shoud raise an exception in failure cases
  #       instead of returning nil
  #
  # Simply wait around for something to show up. This method is similar to
  # performing an explicit search on an element except that the search filters
  # take two extra options which can control how long to wait and from where
  # to start searches from. You __MUST__ supply either the parent or ancestor
  # options to specify where to search from. Searching from the parent implies
  # that what you are waiting for is a child of the parent and not a more
  # distant descendant.
  #
  # This is an alternative to using the notifications system. It is far
  # easier to use than notifications in most cases, but it will perform
  # more slowly (and without all the fun crashes).
  #
  # @example
  #
  #   # Waiting for a dialog window to show up
  #   wait_for :dialog, parent: app
  #
  #   # Waiting for a hypothetical email from Mark Rada to appear
  #   wait_for :static_text, value: 'Mark Rada', ancestor: mail.main_window
  #
  #   # Waiting for something that will never show up
  #   wait_for :a_million_dollars, ancestor: fruit_basket, timeout: 1000000
  #
  # @param [#to_s]
  # @param [Hash] opts
  # @options opts [Number] :timeout (15)
  # @options opts [AX::Element] :parent
  # @options opts [AX::Element] :ancestor
  # @return [AX::Element,nil]
  def wait_for element, opts = {}
    if opts.has_key? :ancestor
      wait_for_descendant element, opts.delete(:ancestor), opts
    elsif opts.has_key? :parent
      wait_for_child element, opts.delete(:parent), opts
    else
      raise ArgumentError, 'parent/ancestor opt required'
    end
  end

  ##
  # Wait around for particular element and then return that element.
  # The options you pass to this method can be any search filter that
  # you can normally use.
  #
  # @param [#to_s]
  # @param [AX::Element]
  # @param [Hash]
  # @return [AX::Element,nil]
  def wait_for_descendant descendant, ancestor, opts
    timeout = opts.delete(:timeout) || 15
    start   = Time.now
    until Time.now - start > timeout
      result = ancestor.search(descendant, opts)
      return result unless result.blank?
      sleep 0.2
    end
    nil
  end

  ##
  # @note This is really just an optimized case of
  #       {wait_for_descendant} when you know what you are waiting
  #       for is a child of a particular element.
  #
  # Wait around for particular element and then return that element.
  # The parent option must be the parent of the element you are
  # waiting for, this method will not look further down the hierarchy.
  # The options you pass to this method can be any search filter that
  # you can normally use.
  #
  # @param [#to_s]
  # @param [AX::Element]
  # @param [Hash]
  # @return [AX::Element,nil]
  def wait_for_child child, parent, opts
    timeout = opts.delete(:timeout) || 15
    start   = Time.now
    q       = Accessibility::Qualifier.new(child.classify, opts)
    until Time.now - start > timeout
      result = parent.children.find { |x| q.qualifies? x }
      return result unless result.blank?
      sleep 0.2
    end
    nil
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
    if Accessibility::Debug.on? && arg.respond_to?(:bounds)
      highlight arg, timeout: 0.2, color: NSColor.orangeColor
    end
    Mouse.move_to arg.to_point
    sleep 0.1
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
    sleep 0.2
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
    sleep 0.1
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
    sleep 0.2
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
    sleep 0.2
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
    sleep 0.2
  end


  # @group Debug

  def highlight element, opts = {}
    Accessibility::Debug.highlight element, opts
  end

  def path_for element
    Accessibility::Debug.path element
  end

  def subtree_for element
    # @todo Create Element#descendants
    Accessibility::Debug.text_subtree element
  end

  ##
  # @note This is an unfinished feature
  #
  # Make a `dot` format graph of the tree, meant for graphing with
  # GraphViz.
  #
  # @return [String]
  def graph element, open = true
    Accessibility::Debug.graph_subtree element
    # @todo Use the `open` flag to decide if it should be sent to
    #       graphviz and opened right away
  end


  # @group Misc.

  ##
  # Convenience for `AX::SystemWide.new`.
  #
  # @return [AX::SystemWide]
  def system_wide
    AX::SystemWide.new
  end


  # @group Macros

  ##
  # Get the current mouse position and return the top most element at
  # that point.
  #
  # @return [AX::Element]
  def element_under_mouse
    element_at_point Mouse.current_position, for: system_wide
  end

  ##
  # Get the top most object at an arbitrary point on the screen. The
  # given point can be a CGPoint, an Array, or anything else that
  # responds to `#to_point`.
  #
  # @param [#to_point]
  # @return [AX::Element]
  def element_at_point point, for: app
    point = point.to_point
    app.element_at_point point.x, point.y
  end

  ##
  # @note This method assumes that the "About" window is an `AX::Dialog`
  #
  # Show the "About" window for an app. Returns the window that is
  # opened.
  #
  # @param [AX::Application]
  # @return [AX::Window]
  def show_about_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title: "About #{app.title}")
    wait_for :dialog, parent: app
  end

  ##
  # @note This method assumes that the app has setup the standard
  #       CMD+, hotkey to open the pref window
  #
  # Try to open the preferences for an app. Returns the window that
  # is opened.
  #
  # @param [AX::Application]
  # @return [AX::Window]
  def show_preferences_window_for app
    windows = app.children.select { |x| x.kind_of? AX::Window }
    type "\\COMMAND+,", app
    new_windows = proc { app.children.select { |x| x.kind_of? AX::Window } }
    while (new_windows.call - windows).empty?
      sleep 0.1
    end
    (new_windows.call - windows).first
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
    move_mouse_to menu

    direction = element.position.y > menu.position.y ? -5 : 5
    until NSContainsRect(menu.bounds, element.bounds)
      scroll direction
    end

    start = Time.now
    until Time.now - start > 5
      # This can happen sometimes with the little arrow bars
      # in menus covering up the menu item.
      if element_under_mouse.kind_of? AX::Menu
        scroll direction
      elsif element_under_mouse != element
        move_mouse_to element
      else
        break
      end
      sleep 0.2
    end
  end

end
