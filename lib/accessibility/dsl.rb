# -*- coding: utf-8 -*-

require 'active_support/core_ext/object/blank'

require 'mouse'
require 'ax/element'
require 'ax/application'
require 'ax/systemwide'
require 'ax/scroll_area'
require 'ax/menu'
require 'accessibility'
require 'accessibility/enumerators'
require 'accessibility/highlighter'


##
# DSL methods for AXElements.
#
# The DSL for AXElements is designed to pull actions out from an object
# and put them in front of object to make communicating test steps seem
# more like human instructions.
#
# You can read more about the DSL in the
# [Acting](http://github.com/Marketcircle/AXElements/wiki/Acting)
# section of the AXElements wiki.
module Accessibility::DSL


  # @!group Actions

  ##
  # We assume that any method that has the first argument with a type
  # of {AX::Element} is intended to be an action and so `#method_missing`
  # will forward the message to the element.
  #
  # @param meth [String] an action constant
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
  # @param element [AX::Element]
  # @return [Boolean]
  def press element
    element.perform :press
  end

  ##
  # Try to perform the `show_menu` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def show_menu element
    element.perform :show_menu
  end

  ##
  # Try to perform the `pick` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def pick element
    element.perform :pick
  end

  ##
  # Try to perform the `decrement` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def decrement element
    element.perform :decrement
  end

  ##
  # Try to perform the `confirm` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def confirm element
    element.perform :confirm
  end

  ##
  # Try to perform the `increment` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def increment element
    element.perform :increment
  end

  ##
  # Try to perform the `delete` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def delete element
    element.perform :delete
  end

  ##
  # Try to perform the `cancel` action on the given element.
  #
  # @param element [AX::Element]
  # @return [Boolean]
  def cancel element
    element.perform :cancel
  end

  ##
  # @note This method overrides `Kernel#raise` so we have to check the
  #       class of the first argument to decide which code path to take.
  #
  # Try to perform the `raise` action on the given element.
  #
  # @overload raise element
  #   @param element [AX::Element]
  #   @return [Boolean]
  #
  # @overload raise exception[, message[, backtrace]]
  #   The normal way to raise an exception.
  def raise *args
    arg = args.first
    arg.kind_of?(AX::Element) ? arg.perform(:raise) : Kernel.raise(*args)
  end

  ##
  # Tell an app to hide itself.
  #
  # @param app [AX::Application]
  # @return [Boolean]
  def hide app
    app.perform :hide
  end

  ##
  # Tell an app to unhide itself.
  #
  # @param app [AX::Application]
  # @return [Boolean]
  def unhide app
    app.perform :unhide
  end
  alias_method :show, :unhide

  ##
  # Tell an app to quit.
  #
  # @param app [AX::Application]
  # @return [Boolean]
  def terminate app
    app.perform :terminate
  end

  ##
  # Focus an element on the screen, but only if it can be directly
  # focused. It is safe to pass any element into this method as nothing
  # will happen if it does not have a writable focused state attribute.
  #
  # @param element [AX::Element]
  def set_focus_to element
    element.set(:focused, true) if element.writable? :focused
  end
  alias_method :set_focus, :set_focus_to

  ##
  # Set the value of an attribute on an element.
  #
  # This method will try to set focus to the element first; this is
  # to compensate for cases where app developers assumed an element
  # would have to have focus before a user could change the value.
  #
  # @overload set element, attribute_name: new_value
  #   Set a specified attribute to a new value
  #   @param element [AX::Element]
  #   @param change [Hash{attribute_name=>new_value}]
  #
  # @example
  #
  #   set text_field, selected_text_range: 1..10
  #
  # @overload set element, new_value
  #   Set the `value` attribute to a new value
  #   @param element [AX::Element]
  #   @param change [Object]
  #
  # @example
  #
  #   set text_field,   'Mark Rada'
  #   set radio_button, 1
  #
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
  # [Keyboard Events](http://github.com/Marketcircle/AXElements/wiki/Keyboarding)
  # wiki page.
  #
  # @overload type string
  #   Send input to the currently focused application
  #   @param string [String]
  #
  # @example
  #
  #   type "Hello, world!"
  #
  # @overload type string, app
  #   Send input to a specific application
  #   @param String [String]
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
  # @param app [AX::Application]
  # @param path [String,Regexp]
  # @return [Boolean]
  def select_menu_item app, *path
    app.application.select_menu_item *path
  end

  ##
  # Show the "About" window for an app. Returns the window that is
  # opened.
  #
  # @param app [AX::Application]
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
  # @param app [AX::Application]
  # @return [AX::Window]
  def show_preferences_window_for app
    app.application.show_preferences_window
  end

  ##
  # Scroll through a scroll area until the given element is visible.
  #
  # If you need to scroll an unknown amount of units through a table
  # or another type of object contained in as scroll area, you can
  # just pass the element that you are trying to get to and this method
  # will scroll to it for you.
  #
  # @example
  #
  #   scroll_to table.rows.last
  #
  # @param element [AX::Element]
  # @return [void]
  def scroll_to element
    element.ancestor(:scroll_area).scroll_to element
  end
  alias_method :scroll_to_visible, :scroll_to

  ##
  # Scroll a menu to an item in the menu and then move the mouse
  # pointer to that item.
  #
  # @example
  #
  #   click window.pop_up do
  #     scroll_menu_to pop_up.menu.item(title: "Expensive Cake")
  #   end
  #
  # @param element [AX::Element]
  # @return [void]
  def scroll_menu_to element
    element.ancestor(:menu).scroll_to element
  end


  # @!group Polling

  ##
  # Simply wait around for something to show up. This method is similar
  # to performing an explicit search on an element except that the search
  # filters take two extra options which can control the timeout period
  # and the search subtree. You __MUST__ supply either the parent or
  # ancestor option to specify where to search from. Searching from the
  # parent implies that what you are waiting for is a child of the parent
  # and not a more distant descendant.
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
  # @param element [#to_s]
  # @param filters [Hash]
  # @option filters [Number] :timeout (5) timeout in seconds
  # @option filters [AX::Element] :parent
  # @option filters [AX::Element] :ancestor
  # @yield Optional block used as a search filter
  # @return [AX::Element,nil]
  def wait_for element, filters = {}, &block
    if filters.has_key? :ancestor
      wait_for_descendant element, filters.delete(:ancestor), filters, &block
    elsif filters.has_key? :parent
      wait_for_child element, filters.delete(:parent), filters, &block
    else
      raise ArgumentError, 'parent/ancestor filter required'
    end
  end

  ##
  # Wait around for particular element and then return that element.
  # The options you pass to this method can be any search filter that
  # you can normally use.
  #
  # See {#wait_for} for more details.
  #
  # @param descendant [#to_s]
  # @param ancestor [AX::Element]
  # @param filters [Hash]
  # @return [AX::Element,nil]
  def wait_for_descendant descendant, ancestor, filters, &block
    timeout = filters.delete(:timeout) || 5
    start   = Time.now
    until Time.now - start > timeout
      result = ancestor.search(descendant, filters, &block)
      return result unless result.blank?
      sleep 0.1
    end
    nil
  end
  alias_method :wait_for_descendent, :wait_for_descendant

  ##
  # @note This is really just an optimized case of
  #       {#wait_for_descendant} when you know what you are waiting
  #       for is a child of a particular element. Use
  #       {#wait_for_descendant} if you are unsure of the relationship.
  #
  # Wait around for particular element and then return that element.
  # The parent argument must be the parent of the element you are
  # waiting for, this method will not look further down the hierarchy.
  # The options you pass to this method can be any search filter that
  # you can normally use.
  #
  # See {#wait_for} for more details.
  #
  # @param child [#to_s]
  # @param parent [AX::Element]
  # @param filters [Hash]
  # @return [AX::Element,nil]
  def wait_for_child child, parent, filters, &block
    timeout = filters.delete(:timeout) || 5
    start   = Time.now
    q       = Accessibility::Qualifier.new(child, filters, &block)
    until Time.now - start > timeout
      result = parent.children.find { |x| q.qualifies? x }
      return result unless result.blank?
      sleep 0.1
    end
    nil
  end

  ##
  # Simply wait for an element to disappear. Optionally wait for the
  # element to appear first.
  #
  # Like {#wait_for}, you can pass any search filters that you normally
  # would, including blocks. However, this method also supports the
  # ability to pass an {AX::Element} and simply wait for it to become
  # invalid.
  #
  # An example usage would be typing into a search field and then
  # waiting for the busy indicator to disappear and indicate that
  # all search results have been returned.
  #
  # @overload wait_for_invalidation_of element
  # @param element [AX::Element]
  # @param filters [Hash]
  # @option filters [Number] :timeout (5) in seconds
  # @return [Boolean]
  #
  # @example
  #
  #   wait_for_invalidation_of table.row(static_text: { value: 'Cake' })
  #
  # @overload wait_for_invalidation_of kind, filters = {}, &block
  # @param element [#to_s]
  # @param filters [Hash]
  # @option filters [Number] :timeout (5) in seconds
  # @return [Boolean]
  #
  # @example
  #
  #   wait_for_invalidation_of :row, parent: table, static_text: { value: 'Cake' }
  #
  # @return [Boolean]
  def wait_for_invalidation_of element, filters = {}, &block
    timeout = filters[:timeout] || 5
    start   = Time.now

    unless element.kind_of? AX::Element
      element = wait_for element, filters, &block
      # this is a tricky situation,
      return true unless element
    end

    until Time.now - start > timeout
      return true if element.invalid?
      sleep 0.1
    end
    false
  end
  alias_method :wait_for_invalidation, :wait_for_invalidation_of
  alias_method :wait_for_invalid,      :wait_for_invalidation_of


  # @!group Mouse Manipulation

  ##
  # Move the mouse cursor to the given point or object on the screen.
  #
  # @example
  #
  #  move_mouse_to button
  #  move_mouse_to [344, 516]
  #  move_mouse_to CGPoint.new(100, 100)
  #
  # @param arg [#to_point]
  # @param opts [Hash]
  # @option opts [Number] :duration (0.2) in seconds
  # @option opts [Number] :wait (0.2) in seconds
  def move_mouse_to arg, opts = {}
    duration = opts[:duration] || 0.2
    if Accessibility.debug? && arg.kind_of?(AX::Element)
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
  # place, or maybe you want to select a group of objects on the screen.
  #
  # @example
  #
  #   drag_mouse_to [100,100]
  #   drag_mouse_to drop_zone, from: desktop_icon
  #
  # @param arg [#to_point]
  # @param opts [Hash]
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
  # @param lines [Number]
  # @param obj [#to_point]
  # @param wait [Number]
  def scroll lines, obj = nil, wait = 0.1
    move_mouse_to obj, wait: 0 if obj
    Mouse.scroll lines
    sleep wait
  end

  ##
  # Perform a regular click.
  #
  # If a parameter is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # If a block is given, it will be yielded to between the click down
  # and click up event.
  #
  # @example
  #
  #   click
  #   click window.close_button
  #   click do
  #     move_mouse_to [0,0]
  #   end
  #
  # @yield Optionally take a block that is executed between click down
  #        and click up events.
  # @param obj [#to_point]
  def click obj = nil, wait = 0.2
    move_mouse_to obj, wait: 0 if obj
    Mouse.click_down
    yield if block_given?
  ensure
    Mouse.click_up
    sleep wait
  end

  ##
  # Perform a right (a.k.a. secondary) click action.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # If a block is given, it will be yielded to between the click down
  # and click up event. This behaviour is the same as passing a block
  # to {DSL#click}.
  #
  # @yield Optionally take a block that is executed between click down
  #        and click up events.
  # @param obj [#to_point]
  def right_click obj = nil, wait = 0.2
    move_mouse_to obj, wait: 0 if obj
    Mouse.right_click_down
    yield if block_given?
  ensure
    Mouse.right_click_up
    sleep wait
  end
  alias_method :secondary_click, :right_click

  ##
  # Perform a double click action.
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param obj [#to_point]
  def double_click obj = nil, wait = 0.2
    move_mouse_to obj, wait: 0 if obj
    Mouse.double_click
    sleep wait
  end

  ##
  # Perform a triple click action
  #
  # If an argument is provided then the mouse will move to that point
  # first; the argument must respond to `#to_point`.
  #
  # @param obj [#to_point]
  def triple_click obj = nil, wait = 0.2
    move_mouse_to obj, wait: 0 if obj
    Mouse.triple_click
    sleep wait
  end


  # @!group Debug Helpers

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
  # @param obj [#bounds]
  # @param opts [Hash]
  # @option opts [Number] :timeout
  # @option opts [NSColor] :colour (NSColor.magentaColor)
  # @return [Accessibility::Highlighter]
  def highlight obj, opts = {}
    Accessibility::Highlighter.new obj.bounds, opts
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
  # @param element [AX::Element]
  # @return [String] path to the saved image
  def graph element
    require 'accessibility/graph'
    graph = Accessibility::Graph.new(element)
    path  = graph.generate_png!
    `open #{path}`
    path
  end
  alias_method :graph_for, :graph

  ##
  # Take a screen shot and save it to disk. If a file name and path are
  # not given then default values will be used; given paths will be
  # expanded automatically.A timestamp and file extension will always
  # automatically be appended to the file name.
  #
  # @example
  #
  #   screenshot
  #     # => "~/Desktop/AXElements-ScreenShot-20120422184650.png"
  #
  #   screenshot app.title
  #     # => "~/Desktop/Safari-20120422184650.png"
  #
  #   screenshot app.title, "/Volumes/SecretStash"
  #     # => "/Volumes/SecretStash/Safari-20120422184650.png"
  #
  # @param name [#to_s]
  # @param dir [#to_s]
  # @return [String] path to the screenshot
  def screenshot name = "AXElements-ScreenShot", dir = '~/Desktop'
    # @todo this could move to its own class, much like
    #       {Accessibility::Highlighter} and expose more options
    #       while retaining good defaults
    dir  = File.expand_path dir.to_s
    file = "#{dir}/#{name}-#{Time.now.strftime '%Y%m%d%H%M%S'}.png"

    cg_image = CGWindowListCreateImage(CGRectInfinite,
                                       KCGWindowListOptionOnScreenOnly,
                                       KCGNullWindowID,
                                       KCGWindowImageDefault)
    NSBitmapImageRep
      .alloc
      .initWithCGImage(cg_image)
      .representationUsingType(NSPNGFileType, properties: nil)
      .writeToFile(file, atomically: false)

    file
  end
  alias_method :capture_screen, :screenshot

  ##
  # See (ScreenRecorder)[http://rdoc.info/gems/screen_recorder/frames]
  # for details on the screen recording options
  #
  # @param file [String]
  # @return [String]
  def record file = nil, &block
    require 'screen_recorder'
    if file
      ScreenRecorder.record file, &block
    else
      ScreenRecorder.record &block
    end
  end

  # @!endgroup


  ##
  # Find the application with the given bundle identifier. If the
  # application is not already running, it will be launched.
  #
  # @example
  #
  #   app_with_bundle_identifier 'com.apple.finder'
  #   launch                     'com.apple.mail'
  #
  # @param id [String]
  # @return [AX::Application,nil]
  def app_with_bundle_identifier id
    AX::Application.new id
  end
  alias_method :app_with_bundle_id, :app_with_bundle_identifier
  alias_method :launch,             :app_with_bundle_identifier

  ##
  # Find the application with the given name. If the application
  # is not already running, it will NOT be launched and this
  # method will return `nil`.
  #
  # @example
  #
  #   app_with_name 'Finder'
  #
  # @param name [String]
  # @return [AX::Application,nil]
  def app_with_name name
    AX::Application.new name
  end

  ##
  # Find the application with the given process identifier. An
  # invalid PID will cause an exception to be raised.
  #
  # @example
  #
  #   app_with_pid 35843
  #
  # @param pid [Fixnum]
  # @return [AX::Application]
  def app_with_pid pid
    AX::Application.new pid
  end

  ##
  # Synonym for `AX::SystemWide.new`.
  #
  # @return [AX::SystemWide]
  def system_wide
    AX::SystemWide.new
  end

  ##
  # Return the top most element at the current mouse position.
  #
  # See {#element_at_point} for more details.
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
  # @param point [#to_point]
  # @param opts [Hash]
  # @option opts [AX::Application] :for
  # @return [AX::Element]
  def element_at_point point, opts = {}
    base = opts[:for] || system_wide
    base.element_at point
  end
  alias_method :element_at, :element_at_point

end
