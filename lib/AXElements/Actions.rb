##
# The idea here is to pull actions out from an object.
# The implementation is optimized under the assumption that you will
# only call a single action on an object and then throw it away.
module Kernel

  ##
  # Focus an element on the screen, if possible.
  def set_focus element
    set element, focused: true
  end

  ##
  # @note Technically, this method allows you to set multiple attributes
  #       on a single object with a single call; but this behaviour is
  #       likely to change in the future to only allow setting one attribute
  #       per call.
  # @todo In order to support the ideal syntax, I will have to alter
  #       Element#method_missing to return a triple (self, attr, value)
  #       in the case when an extra argument is passed.
  #
  # The syntax kinda sucks, and you would think that the #set method should
  # belong to AX::Element, but I think taking it out of the class helps make
  # the abstraction more concrete.
  #
  # @example How to use it
  #   set scroll_bar, value: 10
  # @example How I would like it to work eventually
  #   set scroll_bar.value 10
  #
  # @param [AX::Element] element
  # @param [Hash] changes
  # @return [nil]
  def set element, changes
    raise ArgumentError unless element.kind_of?(AX::Element)
    changes.each_pair do |attr_symbol, value|
      element.set_attribute attr_symbol, value
    end
  end


  alias_method :ax_method_missing, :method_missing
  ##
  # Ideally this method would return a reference to `self`, but since
  # this method inherently causes state change, the reference to `self`
  # may no longer be valid. An example of this would be pressing the
  # close button on a window.
  #
  # @param [String] name an action constant
  def method_missing method, *args
    arg = args.first
    ax_method_missing(method, *args) unless arg.kind_of?(AX::Element)
    arg.perform_action method
  end


  alias_method :ax_raise, :raise
  ##
  # Needed to override inherited {Kernel#raise} so that the raise action
  # works, but in such a way that the original {#raise} also works.
  def raise *args
    arg = args.first
    arg.kind_of?(AX::Element) ? arg.perform_action(:raise) : ax_raise(*args)
  end


  # @param [#to_s] string
  # @param [AX::Application] app
  def type string, app = AX::SYSTEM
    app.post_kb_event string.to_s
  end
end
