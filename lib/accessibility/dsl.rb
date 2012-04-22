# -*- coding: utf-8 -*-

require 'mouse'
require 'ax/element'
require 'ax/application'
require 'ax/systemwide'
require 'accessibility'
require 'accessibility/enumerators'

##
# DSL methods for AXElements.
#
# The idea here is to pull actions out from an object and put them
# in front of object to give AXElements more of a DSL feel to make
# communicating test steps more clear. See the
# [Acting tutorial](http://github.com/Marketcircle/AXElements/wiki/Acting)
# for a more in depth tutorial on using this module.
module Accessibility::DSL


  # @group Actions

  ##
  # We assume that any method that has the first argument with a type
  # of {AX::Element} is intended to be an action and so `#method_missing`
  # will forward the message to the element.
  #
  # @param [String] method an action constant
  def method_missing meth, *args
    arg = args.first
    if arg.kind_of? AX::Element
      return arg.perform meth if arg.actions.include? meth
      raise ArgumentError, "`#{meth}' is not an action of #{self}:#{self.class}"
    end
    # @todo do we still need this? we should just call super
    # should be able to just call super, but there is a bug in MacRuby (#1320)
    # so we just recreate what should be happening
    message = "undefined method `#{meth}' for #{self}:#{self.class}"
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
  #   app_with_bundle_identifier 'com.apple.finder'
  #   launch                     'com.apple.mail'
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
    AX::Application.new name
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
    AX::Application.new pid
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
    # @todo Need to check if arg has the raise action
    arg.kind_of?(AX::Element) ? arg.perform(:raise) : super
  end

  ##
  # Focus an element on the screen if it can be focused. It is safe to
  # pass any element into this method as nothing will happen if it is
  # not capable of having focus set on it.
  #
  # @param [AX::Element]
  def set_focus_to element
    element.set(:focused, true) if element.writable? :focused
  end
  alias_method :set_focus, :set_focus_to

  ##
  # Set the value of an attribute on an element.
  #
  # This method will try to set focus to the element first; this is
  # to avoid cases where developers assumed an element would have
  # to have focus before a user could change the value.
  #
  # @overload set element, attribute_name: new_value
  #   Set a specified attribute to a new value
  #   @param [AX::Element] element
  #   @param [Hash{attribute_name=>new_value}] change
  #
  # @example
  #
  #   set text_field, selected_text_range: CFRangeMake(1,10)
  #
  # @overload set element, new_value
  #   Set the `value` attribute to a new value
  #   @param [AX::Element] element
  #   @param [Object] change
  #
  # @example
  #
  #   set text_field,   'Mark Rada'
  #   set radio_button, 1
  #
  # @return [nil] do not rely on a return value
  def set element, change
    set_focus_to element

    if change.kind_of? Hash
      element.set *change.first
    else
      element.set :value, change
    end
  end

  ##
  # Simulate keyboard input by typing out the given string. To learn
  # more about how to encode modifier keys (e.g. Command), see the
  # dedicated documentation page on
  # [Keyboard Events](http://github.com/Marketcircle/AXElements/wiki/Keyboarding).
  #
  # @overload type string
  #   Send input to the currently focused application
  #   @param [#to_s]
  #
  # @overload type string, app
  #   Send input to a specific application
  #   @param [#to_s]
  #   @param [AX::Application]
  #
  def type string, app = system_wide
    sleep 0.1
    app.type string.to_s
  end
  alias_method :type_string, :type

  ##
  # Navigate the menu bar menus for the given application and select
  # the last item in the chain.
  #
  # @example
  #
  #   mail = app_with_name 'Mail'
  #   select_menu_item mail, 'View', 'Sort By', 'Subject'
  #   select_menu_item mail, 'Edit', /Spelling/, /show spelling/i
  #
  # @param [AX::Application]
  # @param [String,Regexp] path
  # @return [Boolean]
  def select_menu_item app, *path
    app.select_menu_item *path
  end


  # @group Polling

  ##
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
  # @option opts [Number] :timeout (15) timeout in seconds
  # @option opts [AX::Element] :parent
  # @option opts [AX::Element] :ancestor
  # @return [AX::Element,nil]
  def wait_for element, opts = {}, &block
    if opts.has_key? :ancestor
      wait_for_descendant element, opts.delete(:ancestor), opts, &block
    elsif opts.has_key? :parent
      wait_for_child element, opts.delete(:parent), opts, &block
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
  def wait_for_descendant descendant, ancestor, opts, &block
    timeout = opts.delete(:timeout) || 15
    start   = Time.now
    until Time.now - start > timeout
      result = ancestor.search(descendant, opts, &block)
      return result unless result.blank?
      sleep 0.2
    end
    nil
  end
  alias_method :wait_for_descendent, :wait_for_descendant

  ##
  # @note This is really just an optimized case of
  #       {#wait_for_descendant} when you know what you are waiting
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
  def wait_for_child child, parent, opts, &block
    timeout = opts.delete(:timeout) || 15
    start   = Time.now
    q       = Accessibility::Qualifier.new(child, opts, &block)
    until Time.now - start > timeout
      result = parent.children.find { |x| q.qualifies? x }
      return result unless result.blank?
      sleep 0.2
    end
    nil
  end


  # @group Mouse Interaction

  ##
  # Move the mouse cursor to the given point on the screen.
  #
  # @example
  #
  #  move_mouse_to button
  #  move_mouse_to [344, 516]
  #  move_mouse_to CGPoint.new(100, 100)
  #
  # @param [#to_point]
  # @param [Hash] opts
  # @option opts [Number] :duration (0.2) in seconds
  # @option opts [Number] :wait (0.2) in seconds
  def move_mouse_to arg, opts = {}
    duration = opts[:duration] || 0.2
    if Accessibility.debug? && arg.respond_to?(:bounds)
      highlight arg, timeout: duration, color: NSColor.orangeColor
    end
    Mouse.move_to arg.to_point, duration
    sleep(opts[:wait] || 0.2)
  end

  ##
  # Click and drag the mouse from its current position to the given
  # position.
  #
  # There are many reasons why you would want to cause a drag event
  # with the mouse. Perhaps you want to drag an object to another
  # place, or maybe you want to hightlight an area of the screen.
  #
  # @example
  #
  #   drag_mouse_to [100,100]
  #   drag_mouse_to drop_zone, from: desktop_icon
  #
  # @param [#to_point]
  # @param [Hash] opts
  # @option opts [#to_point] :from a point to move to before dragging
  # @option opts [Number] :duration (0.2) in seconds
  # @option opts [Number] :wait (0.2) in seconds
  def drag_mouse_to arg, opts = {}
    move_mouse_to opts[:from] if opts[:from]
    Mouse.drag_to arg.to_point, (opts[:duration] || 0.2)
    sleep(opts[:wait] || 0.2)
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
  def scroll lines, obj = nil, wait = 0.1
    move_mouse_to obj, wait: 0 if obj
    Mouse.scroll lines
    sleep wait
  end

  ##
  # Perform a regular click.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param [#to_point]
  def click obj = nil, wait = 0.2
    if obj
      point = obj.to_point
      move_mouse_to point, wait: 0
      if Mouse.current_position != point
        move_mouse_to point, wait: 0
      end
    end
    Mouse.click
    sleep wait
  end

  ##
  # Perform a right (aka secondary) click action.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param [#to_point]
  def right_click obj = nil, wait = 0.2
    move_mouse_to obj, wait: 0 if obj
    Mouse.right_click
    sleep wait
  end
  alias_method :secondary_click, :right_click

  ##
  # Perform a double click action.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param [#to_point]
  def double_click obj = nil, wait = 0.2
    move_mouse_to obj, wait: 0 if obj
    Mouse.double_click
    sleep wait
  end


  # @group Debug

  ##
  # Highlight an element on screen. You can optionally specify the
  # highlight colour or pass a timeout to automatically have the
  # highlighter disappear.
  #
  # The highlighter is actually a window, so if you do not set a
  # timeout, you will need to call `#stop` or `#close` on the returned
  # highlighter object in order to get rid of the highlighter.
  #
  # You could use this method to highlight an arbitrary number of
  # elements on screen, with a rainbow of colours. Great for debugging.
  #
  # @example
  #
  #   highlighter = highlight window.outline
  #   # wait a few seconds...
  #   highlighter.stop
  #
  #   # highlighter automatically turns off after 5 seconds
  #   highlight window.outline.row, colour: NSColor.greenColor, timeout: 5
  #
  # @param [#bounds]
  # @param [Hash] opts
  # @option opts [Number] :timeout
  # @option opts [NSColor] :colour (NSColor.magentaColor)
  # @return [Accessibility::Highlighter]
  def highlight obj, opts = {}
    require 'accessibility/highlighter'
    Accessibility::Highlighter.new obj.bounds, opts
  end

  ##
  # Dump a tree to the console, indenting for each level down the
  # tree that we go, and inspecting each element.
  #
  # @example
  #
  #   puts subtree_for app
  #
  # @return [String]
  def subtree_for element
    output = element.inspect + "\n"
    enum   = Accessibility::Enumerators::DepthFirst.new element
    enum.each_with_level do |element, depth|
      output << "\t"*depth + element.inspect + "\n"
    end
    output
  end

  ##
  # @note You will need to have GraphViz command line tools installed
  #       in order for this to work.
  #
  # Make and open a `dot` format graph of the tree, meant for graphing
  # with GraphViz.
  #
  # @example
  #
  #   graph app.main_window
  #
  # @param [AX::Element]
  # @return [String] path to the saved image
  def graph element
    require 'accessibility/graph'
    graph = Accessibility::Graph.new(element)
    graph.build!

    require 'tempfile'
    file = Tempfile.new('graph')
    File.open(file.path, 'w') do |fd| fd.write graph.to_dot end
    `dot -Tpng #{file.path} > #{file.path}.png`
    `open #{file.path}.png`

    file.path
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
    element_at_point Mouse.current_position
  end

  ##
  # Get the top most object at an arbitrary point on the screen for
  # the given application. The given point can be a CGPoint, an Array,
  # or anything else that responds to `#to_point`.
  #
  # Optionally, you can look for the top-most element for a specific
  # application by passing an {AX::Application} object using the `for:`
  # key.
  #
  # @example
  #
  #   element_at [100, 456]
  #   element_at CGPoint.new(33, 45), for: safari
  #
  #   element_at window # find out what is in the middle of the window
  #
  # @param [#to_point]
  # @param [Hash] opts
  # @option opts [AX::Application] :for
  # @return [AX::Element]
  def element_at_point point, opts = {}
    base = opts[:for] || system_wide
    base.element_at point
  end

  ##
  # Show the "About" window for an app. Returns the window that is
  # opened.
  #
  # @param [AX::Application]
  # @return [AX::Window]
  def show_about_window_for app
    app.show_about_window
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
    app.show_preferences_window
  end

  ##
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
      Mouse.scroll direction
    end
    sleep 0.1
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
      Mouse.scroll direction
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
    end
  end

end
