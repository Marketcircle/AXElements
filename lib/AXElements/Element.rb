require 'AXElements/Element/Searching'
require 'AXElements/Element/Notifications'
require 'AXElements/Element/Clicking'

module AX

##
# @abstract
#
# The abstract base class for all accessibility objects.
class Element

  # @return [Array<String>] A cache of available attributes
  attr_reader :attributes

  # @return [Array<String>] A cache of available actions
  attr_reader :actions

  # @return [AXUIElementRef] the low level object reference
  attr_reader :ref

  # @param [AXUIElementRef] element
  def initialize element
    @ref        = element
    @attributes = AX.attrs_of_element(element)
    @actions    = AX.actions_of_element(element)
  end

  # @return [Fixnum]
  def pid
    @pid ||= ( ptr = Pointer.new 'i' ; AXUIElementGetPid( @ref, ptr ) ; ptr[0] )
  end

  # @param [String] attribute an attribute constant
  def get_attribute attribute
    AX.attr_of_element(@ref, attribute)
  end

  ##
  # @param [Symbol] attr
  # @return [Boolean]
  def attribute_writable? attr
    ptr         = Pointer.new('B')
    unless method_name = attribute_for_symbol(attr)
      raise ArgumentError, "#{attr} is not an attribute of this #{self.class}"
    end
    code  = AXUIElementIsAttributeSettable( @ref, method_name, ptr )
    log_ax_call(@ref, code)
    ptr[0]
  end

  ##
  # Like the {#perform_action} method, we cannot make any assumptions
  # about the state of the program after you have set a value; at
  # least not in the general case. So, the best we can do here is
  # return true if there were no issues.
  #
  # @param [String] attr
  # @return [Boolean] true if successful, otherwise false
  def set_attribute_with_value attr, value
  end

  ##
  # Ideally this method would return a reference to self, but as the
  # method inherently causes state change the reference to self may no
  # longer be valid. An example of this would be pressing the close
  # button on a window.
  #
  # @param [String] action_name
  # @return [Boolean] true if successful, otherwise false
  def perform_action action_name
  def set_attribute attr, value
    code = AXUIElementSetAttributeValue( @ref, attr, value )
    log_ax_call( @ref, code ) == 0
  end

  ##
  # Focus an element on the screen, if possible.
  def get_focus
    raise NoMethodError unless attributes.include?(KAXFocusedAttribute)
    self.set_attribute(KAXFocusedAttribute, true)
  end

  ##
  # Set the value of an element that has a value, such as a text box or
  # a slider. You need to be weary of the type that the value is expected
  # to be.
  def value= val
    raise NoMethodError unless attributes.include?(KAXFocusedAttribute)
    self.set_attribute(KAXValueAttribute, val)
  end
    code = AXUIElementPerformAction( @ref, action_name )
    log_ax_call( @ref, code ) == 0
  end

  ##
  # @note Some attribute names don't map consistently from Apple's
  #       documentation because it would have caused a clash with the
  #       two systems used for attribute lookup and searching/filtering.
  #
  # We use {#method missing} to dynamically handle requests to, in the
  # following order, lookup attributes, perform actions, or search for
  # elements in the view hierarchy.
  #
  # Failing all three lookups, this method calls super.
  #
  # @example Attribute lookup of an element
  #  mail   = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  #  window = mail.focused_window
  # @example Attribute lookup of an element property
  #  window.title
  # @example Simple single element search
  #  window.button # => You want the first Button that is found
  # @example Simple multi-element search
  #  window.buttons # => You want all the Button objects found
  # @example Filters for a single element search
  #  window.button(title:'Log In') # => First Button with a title of 'Log In'
  # @example Contrived multi-element search with filtering
  #  window.buttons(title:'New Project', enabled?:true)
  def method_missing method, *args
    attr = attribute_for_symbol(method)
    return self.get_attribute(attr) if attr

    action = action_for_symbol(method)
    return self.perform_action(action) if action

    if attributes.index(KAXChildrenAttribute)
      return self.search(method, args.first)
    end

    super
  end

  # @endgroup
  # @group Overridden methods

  ##
  # Needed to override inherited {#raise} so that the raise action works,
  # but in such a way that the original {#raise} also works.
  def raise *args
    self.method_missing(:raise) || super
  end

  ##
  # Needed to override inherited NSObject#description. If you want a
  # description of the object try using {#inspect}.
  def description
    self.method_missing :description
  end

  ##
  # @todo finish this method
  #
  # A more expensive {#inspect} where we actually look up the
  # values for each attribute and format the output nicely.
  def pretty_print
    inspect
  end

  ##
  # Method is overriden to produce cleaner output.
  def inspect
    nice_methods = (attributes + actions).map { |name|
      name.sub(AX.accessibility_prefix) { $1 }
    }
    "\#<#{self.class} @methods=#{nice_methods}>"
  end

  ##
  # This helps a bit with regards to the dynamic attribute and action
  # lookups, but will return false on potential search names.
  #
  # @param [Symbol] name
  def respond_to? name
    pattern = matcher(name)
    return true if (attributes + actions).find { |meth| meth.match(pattern) }
    return attributes.include?(KAXFocusedAttribute) if name == :get_focus
    return attributes.include?(KAXValueAttribute)   if name == :value=
    super
  end


  protected

  ##
  # Make a regexp that can match against the proper attributes
  # and/or actions for an AX::Element object.
  def matcher name
    /#{name.to_s.gsub(/_|\?$/, '')}$/i
  end

  # @return [String,nil]
  def attribute_for_symbol sym
    pattern = matcher(sym)
    matches = attributes.find_all { |attr| attr.match(pattern) }
    unless matches.empty?
      matches.sort_by(&:length) if matches.size > 1
      matches.first
    end
  end

  # @return [String,nil]
  def action_for_symbol sym
    pattern = matcher(sym)
    actions.find { |action| action.match(pattern) }
  end

end
end
