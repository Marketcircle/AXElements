require 'ax/element'
require 'accessibility/string'

##
# Represents the special `SystemWide` accessibility object.
#
# Previously, this object was a singleton, but that apparently causes
# problems with the AXAPIs. So you should always create a new instance
# of the system wide object when you need to use it (even though they
# are all the same thing).
class AX::SystemWide < AX::Element
  include Accessibility::String

  class << self
    ##
    # Find and return the group that represents the dock
    #
    # @return [AX::Group]
    def desktop
      AX::Application.finder.scroll_areas.first.groups.first
    end

    ##
    # @note This currently does not include spotlight or the
    #       notification center as they interact oddly with
    #       accessibility APIs and how AXElements handle errors
    #
    # Find and return menu bar items for the system
    #
    # That is, menu bar items that do not belong to the current
    # app, but that belong to the system, such as the clock or
    # wi-fi menu.
    #
    # @return [AX::MenuBarItem]
    def status_items
      AX::Application.new('SystemUIServer').menu_bar.children
    end
  end


  ##
  # Overridden since there is only one way to get the element ref.
  def initialize
    super AXUIElementCreateSystemWide()
  end

  ##
  # @note With the `SystemWide` class, using {#type} will send the
  #       events to which ever app has focus.
  #
  # Generate keyboard events by simulating keyboard input.
  #
  # See the
  # [Keyboarding documentation](http://github.com/Marketcircle/AXElements/wiki/Keyboarding)
  # for more information on how to format strings.
  #
  # @param string [String]
  # @return [Boolean]
  def type string
    @ref.post keyboard_events_for string
    true
  end
  alias_method :type_string, :type

  ##
  # Press the given modifier key and hold it down while yielding to the
  # given block.
  #
  # @example
  #
  #   hold_key "\\CONTROL" do
  #     drag_mouse_to point
  #   end
  #
  # @param key [String]
  # @return [Number,nil]
  def hold_modifier key
    code = EventGenerator::CUSTOM[key]
    raise ArgumentError, "Invalid modifier `#{key}' given" unless code
    @ref.post [[code, true]]
    yield
  ensure # if block raises the button might stuck, so ensure it is released
    @ref.post [[code,false]] if code
    code
  end

  ##
  # The system wide object cannot be used to perform searches. This method
  # is just an override to avoid a difficult to understand error messages.
  def search *args
    raise NoMethodError, 'AX::SystemWide cannot search'
  end

  ##
  # Raises an `NoMethodError` instead of (possibly) silently failing to
  # register for a notification.
  #
  # @raise [NoMethodError]
  def on_notification *args
    raise NoMethodError, 'AX::SystemWide cannot register for notifications'
  end

  ##
  # Find the element in at the given point for the topmost appilcation
  # window.
  #
  # `nil` will be returned if there was nothing at that point.
  #
  # @param point [#to_point]
  # @return [AX::Element,nil]
  def element_at point
    @ref.element_at(point).to_ruby
  end

  ##
  # Set the global messaging timeout. Searching through another interface
  # and looking up attributes incurs a lot of IPC calls and sometimes an
  # app is slow to respond.
  #
  # @param seconds [Number]
  # @return [Number]
  def set_global_timeout seconds
    @ref.set_timeout_to seconds
  end

end
