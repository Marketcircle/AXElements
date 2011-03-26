require 'AXElements/Element/Searching'
require 'AXElements/Element/Notifications'
require 'AXElements/Element/Clicking'

module AX

##
# @abstract
#
# The abstract base class for all accessibility objects.
class Element

  # @return [Array<String>] cache of available attributes
  attr_reader :attributes

  # @return [Array<String>] cache of available actions
  attr_reader :actions

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

  # @param [String] attr an attribute constant
  def get_attribute attr
    AX.attr_of_element(@ref, attr)
  end
  # @param attr an attribute constant
  def attribute_writable? attr
    raise ArgumentError, "#{attr} not found" unless attributes.include? attr
    ptr  = Pointer.new('B')
    code = AXUIElementIsAttributeSettable( @ref, attr, ptr )
    AX.log_ax_call @ref, code
    ptr[0]
  end

  ##
  # @todo should we check existence to be nice?
  #
  # @param attr an attribute constant
  def get_attribute attr
#    raise ArgumentError, "#{attr} not found" unless attributes.include? attr
    AX.attr_of_element( @ref, attr )
  end

  ##
  # @todo merge this into other places once I understand it more,
  #       right now it would just add a lot of overhead
  def get_param_attribute attr, param
    @param_attrs ||= AX.param_attrs_of_element(@ref)
    raise NoMethodError, "#{self.class} has no paramterized attrs" unless @param_attrs
    raise ArgumentError, "#{attr} not found" unless @param_attrs.include? attr
    return AX.param_attr_of_element( @ref, attr, param )
  end

  # Like the {#perform_action} method, we cannot make any assumptions
  # about the state of the program after you have set a value; at
  # least not in the general case.
  #
  # @param [String] attr an attribute constant
  # @return the value that you set is returned
  def set_attribute attr, value
    code = AXUIElementSetAttributeValue( @ref, attr, value )
    AX.log_ax_call @ref, code
    value
  end

  ##
  # Focus an element on the screen, if possible.
  def set_focus
    raise NoMethodError unless attributes.include?(KAXFocusedAttribute)
    self.set_attribute(KAXFocusedAttribute, true)
  end

  ##
  # @todo Actions and attribute setters should be the first step in
  #       making a DSL; that way the responsibility of {#method_missing}
  #       can be reduced to information retrieval (attributes.searching),
  #       and the DSL will be centered around calling actions and setters
  #       on attributes and objects; verification will be left to testing
  #       suites
  #
  # Ideally this method would return a reference to `self`, but since
  # this method inherently causes state change, the reference to `self`
  # may no longer be valid. An example of this would be pressing the
  # close button on a window.
  #
  # @param [String] action_name an action constant
  # @return [Boolean] true if successful
  def perform_action action_name
    code = AXUIElementPerformAction( @ref, action_name )
    AX.log_ax_call( @ref, code ) == 0
  end

  ##
  # We use {#method missing} to dynamically handle requests to, in the
  # following order, lookup attributes, perform actions, or search for
  # elements in the view hierarchy.
  #
  # Failing all three lookups, this method calls `super`.
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
    set  = method.to_s.chomp! '='
    attr = attribute_for method
    return set_attribute(attr, args.first) if set && attr
    return get_attribute(attr)             if attr

    action = action_for_symbol(method)
    return self.perform_action(action) if action

    if attributes.index(KAXChildrenAttribute)
      return self.search(method, args.first)
    end

    super
  end

  ##
  # Needed to override inherited {Kernel#raise} so that the raise action works,
  # but in such a way that the original {#raise} also works.
  def raise *args
    self.method_missing(:raise) || super
  end

  ##
  # Needed to override inherited NSObject#description. If you want a
  # description of the object try using {#inspect}.
  def description
    self.method_missing(:description)
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
      name.sub(AX.prefix) { $1 }
    }
    "\#<#{self.class} @methods=#{nice_methods}>"
  end

  ##
  # @todo respond appropriately for setter type methods
  #
  # This helps a bit with regards to the dynamic attribute and action
  # lookups, but will return false on potential search names.
  #
  # @param [Symbol] name
  def respond_to? name
    pattern = matcher(name)
    return true if (attributes + actions).find { |meth| meth.match(pattern) }
    return attributes.include?(KAXFocusedAttribute) if name == :set_focus
    super
  end


  protected

  ##
  # Make a regexp that can match against the proper attributes
  # and/or actions for an AX::Element object.
  def matcher name
    /#{name.to_s.gsub(/_|\?$/, '')}$/i
  end

  def attribute_for       sym; constant_for sym, attributes;       end
  def action_for          sym; constant_for sym, actions;          end

  ##
  # Match a symbol/string as a suffix of an action constant
  # @return [String,nil]
  def constant_for sym, array
    pattern = matcher(sym)
    matches = array.find_all { |const| const.match(pattern) }
    unless matches.empty?
      matches.sort_by(&:length) if matches.size > 1
      matches.first
    end
  end

end
end
