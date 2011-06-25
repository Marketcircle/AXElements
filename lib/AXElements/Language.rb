# -*- coding: utf-8 -*-

##
# @todo Allow the animation duration to be overridden for Mouse stuff
#
# The idea here is to pull actions out from an object and put them
# in front of object to give AXElements more of a DSL feel to make
# communicating test steps more clear.
module Accessibility::Language

  # @group Actions

  ##
  # We assume that any method that has the first argument with a type
  # of AX::Element is intended to be an action and so #method_missing
  # will forward the message to the element.
  #
  # @param [String] name an action constant
  def method_missing method, *args
    arg = args.first
    unless arg.kind_of?(AX::Element)
      # should be able to just call super, but there is a bug in MacRuby (#1320)
      # so we just recreate what should be happening
      message = "undefined method `#{method}' for #{self}:#{self.class}"
      raise NoMethodError, message, caller(1)
    end
    arg.perform_action method
  end

  ##
  # Needed to override inherited {Kernel#raise} so that the raise action
  # works, but in such a way that the original {#raise} also works.
  def raise *args
    arg = args.first
    arg.kind_of?(AX::Element) ? arg.perform_action(:raise) : super
  end

  ##
  # Focus an element on the screen, but do not set focus again if
  # already focused.
  def set_focus element
    element.set_attribute(:focused, true) unless element.focused?
  end

  ##
  # @note We try to set focus to the element first; this is to avoid false
  #       positives where developers assumed an element would have to have
  #       focus before a user could change the value.
  #
  # You would think that the #set method should belong to {AX::Element},
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
    set_focus element
    key, value = change.is_a?(Hash) ? change.first : [:value, change]
    element.set_attribute key, value
  end

  # @group Keyboard input

  ##
  # Simulate keyboard input by typing out the given string. To learn
  # more about how to encode modifier keys (e.g. Command), see the
  # dedicated documentation page on
  # {file:docs/KeyboardEvents.markdown Keyboard Events}.
  #
  # @overload type 'Hello'
  #   Send input to the currently focused application
  #   @param [#to_s] string
  #
  # @overload type 'Hello', app
  #   Send input to a specific application
  #   @param [#to_s] string
  #   @param [AX::Application] app
  def type string, app = AX::SYSTEM
    app.type_string string.to_s
  end

  # @group Notifications

  ##
  # @todo Change this to register_for_notification:from: when the syntax
  #       is supported by YARD or someone complains, which ever comes
  #       first.
  #
  # @param [AX::Element] element
  # @param [String] notif
  def register_for_notification element, notif, &block
    element.on_notification notif, &block
  end

  # @param [Float] timeout number of seconds to wait for a notification
  def wait_for_notification timeout = 10.0
    AX.wait_for_notif timeout
  end

  # @group Mouse input

  ##
  # @todo If the method is given an element as an argument then we
  #       should only move if current mouse position is not over
  #       the element (use NSPointInRect()).
  #
  # @overload move_mouse_to(element)
  #   Move the mouse to a UI element
  #   @param [AX::Element] arg
  #
  # @overload move_mouse_to(point)
  #   Move the mouse to an arbitrary point
  #   @param [CGPoint] arg
  #
  # @overload move_mouse_to([x,y])
  #   Move the mouse to an arbitrary point given as an two element array
  #   @param [Array(Float,Float)] arg
  def move_mouse_to arg
    Mouse.move_to arg.to_point
  end

  ##
  # There are many reasons why you would want to cause a drag event
  # with the mouse. Perhaps you want to drag an object to another
  # place, or maybe you want to hightlight an area of the screen.
  #
  # In the most general of cases, you are alawys dragging to a point,
  # but having to specify the point yourself is not very helpful.
  #
  # We try to inspect the arguments of this method in order to better
  # determine what it is you want.
  def drag_mouse_to arg
    arg = if arg.kind_of?(AX::Element)
            CGPoint.center(arg.position, arg.size)
          elsif arg === Array
            CGPoint.new(*arg)
          end
    Mouse.drag_to arg
  end

  ##
  # @todo You really want to be able to pass a scroll bar element
  #       and have the API move the mouse to the appropriate area
  #       and then run the scroll event(s).
  # @todo Need to expose the units option
  def scroll lines, element = nil
    move_mouse_to element if element
    Mouse.scroll lines
  end

  def click element = nil
    move_mouse_to element if element
    Mouse.click
  end

  def right_click element = nil
    move_mouse_to element if element
    Mouse.right_click
  end

  def double_click element = nil
    raise NotImplementedError, 'Please implement me. :('
  end

  # @group Macros

  ##
  # A macro for showing the About window for an app.
  def show_about_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title: "About #{app.title}")
  end

  ##
  # A macro for showing the About window for an app.
  def show_preferences_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title:'Preferences…')
  end

end
