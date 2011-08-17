# -*- coding: utf-8 -*-

require 'mouse'

##
# @todo Allow the animation duration to be overridden for Mouse stuff
#
# The idea here is to pull actions out from an object and put them
# in front of object to give AXElements more of a DSL feel to make
# communicating test steps more clear. See the
# {file:docs/Acting.markdown Acting} tutorial for examples on how to use
# methods from this module.
module Accessibility::Language

  # @group Actions

  ##
  # We assume that any method that has the first argument with a type
  # of {AX::Element} is intended to be an action and so `#method_missing`
  # will forward the message to the element.
  #
  # @param [String] method an action constant
  def method_missing method, *args
    arg = args.first
    unless arg.kind_of? AX::Element
      # should be able to just call super, but there is a bug in MacRuby (#1320)
      # so we just recreate what should be happening
      message = "undefined method `#{method}' for #{self}:#{self.class}"
      raise NoMethodError, message
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
    element.set_attribute(:focused, true) unless element.attribute(:focused?)
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
    set_focus element if element.attribute_writable? :focused
    key, value = change.is_a?(Hash) ? change.first : [:value, change]
    element.set_attribute key, value
  end

  ##
  # Simulate keyboard input by typing out the given string. To learn
  # more about how to encode modifier keys (e.g. Command), see the
  # dedicated documentation page on
  # {file:docs/KeyboardEvents.markdown Keyboard Events}.
  #
  # @overload type 'Hello'
  #   Send input to the currently focused application
  #   @param [#to_s]
  #
  # @overload type 'Hello', app
  #   Send input to a specific application
  #   @param [#to_s]
  #   @param [AX::Application]
  def type string, app = AX::SYSTEM
    app.type_string string.to_s
  end

  # @group Notifications

  ##
  # @todo Change this to register_for_notification:from: when the syntax
  #       is supported by YARD or someone complains, which ever comes
  #       first.
  #
  # @param [AX::Element]
  # @param [String]
  def register_for_notification element, notif, &block
    element.on_notification notif, &block
  end

  # @param [Float] timeout number of seconds to wait for a notification
  def wait_for_notification timeout = 10.0
    AX.wait_for_notif timeout
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
  # but you could pass anything that responds to #to_point.
  #
  # @param [#to_point]
  def drag_mouse_to arg
    Mouse.drag_to point.to_point
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
  # A macro for showing the preferences for an app.
  def show_preferences_window_for app
    set_focus app
    press app.menu_bar_item(title:(app.title))
    press app.menu_bar.menu_item(title:'Preferences…')
  end

end
