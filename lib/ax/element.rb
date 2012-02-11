# -*- coding: utf-8 -*-

require 'ax_elements/macruby_extensions'
require 'ax_elements/vendor/inflector'
require 'accessibility/factory'
require 'accessibility/enumerators'
require 'accessibility/qualifier'
require 'accessibility/errors'
require 'accessibility/pp_inspector'


##
# Namespace container for all the accessibility objects.
module AX
end

##
# @abstract
#
# The abstract base class for all accessibility objects. This class
# provides generic functionality that all accessibility objects require.
class AX::Element
  include Accessibility::PPInspector
  include Accessibility::Factory


  # @param [AXUIElementRef]
  # @param [Array<String>]
  def initialize ref, attrs
    @ref   = ref
    @attrs = attrs
  end


  # @group Attributes

  ##
  # Cache of available attributes.
  #
  # @example
  #
  #   window.attributes # => [:size, :position, :title, ...]
  #
  # @return [Array<Symbol>]
  def attributes
    @attributes ||= TRANSLATOR.rubyize @attrs
  end

  ##
  # Get the value of an attribute.
  #
  # @example
  #
  #   element.attribute :position # => #<CGPoint x=123.0 y=456.0>
  #
  # @param [Symbol]
  def attribute attr
    real_attr = lookup attr, with: @attrs
    raise Accessibility::LookupFailure.new(self, attr) unless real_attr
    process attr(real_attr, for: @ref)
  end

  ##
  # Needed to override inherited `NSObject#description`. If you want a
  # description of the object then you should use {#inspect} instead.
  def description
    attribute :description
  end

  ##
  # Return the `#size` of an attribute. This only works for attributes
  # that are a collection. This exists because it is _much_ more
  # efficient to find out how many `children` exist using this API
  # instead of getting the children array and asking for the size.
  #
  # @example
  #
  #   table.size_of  :rows     # => 111
  #   window.size_of :children # => 16
  #
  # @param [Symbol]
  # @return [Number]
  def size_of attr
    real_attr = lookup attr, with: @attrs
    raise Accessibility::LookupFailure.new(self, attr) unless real_attr
    size_of real_attr, for: @ref
  end

  ##
  # Get the process identifier for the application that the element
  # belongs to.
  #
  # @example
  #
  #   element.pid # => 12345
  #
  # @return [Fixnum]
  def pid
    @pid ||= pid_for @ref
  end

  ##
  # Check whether or not an attribute is writable.
  #
  # @example
  #
  #   element.writable_attribute? :size  # => true
  #   element.writable_attribute? :value # => false
  #
  # @param [Symbol] attr
  def writable_attribute? attr
    real_attr = lookup attr, with: @attrs
    raise Accessibility::LookupFailure.new(self, attr) unless real_attr
    writable_attr? real_attr, for: @ref
  end

  ##
  # Set a writable attribute on the element to the given value.
  #
  # @example
  #
  #   element.set :value, to: 'Hello, world!'
  #   element.set :size,  to: [100, 200].to_size
  #
  # @param [String] attr an attribute constant
  # @return the value that you were setting is returned
  def set attr, to: value
    unless writable_attribute? attr
      raise NoMethodError, "#{attr} is read-only for #{inspect}"
    end
    real_attr = lookup attr, with: @attrs
    set real_attr, to: value.to_axvalue, for: @ref
    value
  end


  # @group Parameterized Attributes

  ##
  # List of available parameterized attributes. Most elements have no
  # parameterized attributes, but the ones that do have many.
  #
  # @example
  #
  #   window.param_attributes     # => []
  #   text_field.param_attributes # => [:string_for_range, :attributed_string, ...]
  #
  # @return [Array<String>]
  def parameterized_attributes
    TRANSLATOR.rubyize _parameterized_attributes
  end

  ##
  # Get the value for a parameterized attribute.
  #
  # @example
  #
  #  text_field.attribute :string_for_range, for_param: (2..8).relative_to(10)
  #
  # @param [Symbol]
  def attribute attr, for_parameter: param
    real_attr = lookup attr, with: _parameterized_attributes
    raise Accessibility::LookupFailure.new(self, attr) unless real_attr
    process param_attr(real_attr, for_param: param.to_axvalue, for: @ref)
  end


  # @group Actions

  ##
  # List of available actions.
  #
  # @example
  #
  #   toolbar.actions # => []
  #   button.actions  # => [:press]
  #   menu.actions    # => [:open, :cancel]
  #
  # @return [Array<String>]
  def actions
    TRANSLATOR.rubyize _actions
  end

  ##
  # Tell an object to trigger an action.
  #
  # For instance, you can tell a button to call the same method that
  # would be called when pressing a button, except that the mouse will
  # not move over to the button to press it, nor will the keyboard be
  # used.
  #
  # @example
  #
  #   button.perform :press # => true
  #
  # @param [String] action an action constant
  # @return [Boolean] true if successful
  def perform action
    real_action = lookup action, with: _actions
    raise Accessibility::LookupFailure.new(self, action) unless real_action
    perform real_action, for: @ref
  end


  # @group Search

  ##
  # Perform a breadth first search through the view hierarchy rooted at
  # the current element.
  #
  # See the {file:docs/Searching.markdown Searching} tutorial for the
  # details on searching.
  #
  # @example Find the dock icon for the Finder app
  #
  #   AX::DOCK.search( :application_dock_item, title:'Finder' )
  #
  # @param [#to_s]
  # @param [Hash{Symbol=>Object}]
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search kind, filters = {}
    kind      = kind.camelize
    klass     = kind.singularize
    search    = klass == kind ? :find : :find_all
    qualifier = Accessibility::Qualifier.new(klass, filters)
    tree      = Accessibility::Enumerators::BreadthFirst.new(self)

    tree.send(search) { |element| qualifier.qualifies? element }
  end

  ##
  # Search for an ancestor of the current elemenet.
  #
  # As the opposite of {#search}, this also takes filters, and can
  # be used to find a specific ancestor for the current element.
  #
  # @example
  #
  #   button.ancestor :window       # => #<AX::StandardWindow>
  #   row.ancestor    :scroll_area  # => #<AX::ScrollArea>
  #
  # @param [#to_s]
  # @param [Hash{Symbol=>Object}]
  # @return [AX::Element]
  def ancestor kind, filters = {}
    qualifier = Accessibility::Qualifier.new(kind.camelize, filters)
    element   = attribute :parent
    until qualifier.qualifies? element
      element = element.attribute :parent
    end
    element
  end

  ##
  # We use {#method_missing} to dynamically handle requests to lookup
  # attributes or search for elements in the view hierarchy. An attribute
  # lookup is always tried first, followed by a parameterized attribute
  # lookup, and then finally a search.
  #
  # Failing all lookups, this method calls `super`.
  #
  # @example
  #
  #   mail   = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  #
  #   # attribute lookup
  #   window = mail.focused_window
  #   # is equivalent to
  #   window = mail.attribute :focused_window
  #
  #   # parameterized attribute lookup
  #   window.title_ui_element.string_for_range (1..10).relative_to(100)
  #   # is equivalent to
  #   title = window.attribute :title_ui_element
  #   title.param_attribute :string_for_range, for_param: (1..10).relative_to(100)
  #
  #   # simple single element search
  #   window.button # => You want the first Button that is found
  #   # is equivalent to
  #   window.search :button, {}
  #
  #   # simple multi-element search
  #   window.buttons # => You want all the Button objects found
  #   # is equivalent to
  #   window.search :buttons, {}
  #
  #   # filters for a single element search
  #   window.button(title: 'Log In') # => First Button with a title of 'Log In'
  #   # is equivalent to
  #   window.search :button, title: 'Log In'
  #
  #   # attribute and element search failure
  #   window.application # => SearchFailure is raised
  #
  def method_missing method, *args
    attribute = lookup method, with: @attrs
    if attribute
      return process attr(attribute, for: @ref)
    end

    attribute = lookup method, with: _parameterized_attributes
    if attribute
      return process param_attr(attribute, for_param: args.first, for: @ref)
    end

    if @attrs.include? KAXChildrenAttribute
      result = search method, *args
      return result unless result.blank?
      raise Accessibility::SearchFailure.new(self, method, args.first)
    end

    super
  end


  # @group Notifications

  ##
  # Register a callback block to run when a notification is sent by
  # the object.
  #
  # The block is optional. The block will be given the sender of the
  # notification, which will almost always be `self`, and also the name
  # of the notification being received. The block should return a
  # boolean value that decides if the notification received is the
  # expected one.
  #
  # Read the {file:docs/Notifications.markdown Notifications tutorial}
  # for more information.
  #
  # @param [#to_s]
  # @yieldparam [String]
  # @yieldparam [AX::Element]
  # @yieldreturn [Boolean]
  # @return [Array(String,self)] the notification/element pair
  def on_notification name, &block
    notif = TRANSLATOR.guess_notification_for name
    register_to_receive notif, from: @ref do |notification, sender|
      element = process sender
      block ? block.call(notification, element) : true
    end
    [notif, self]
  end

  # @endgroup


  ##
  # Overriden to produce cleaner output.
  #
  # @return [String]
  def inspect
    msg  = "#<#{self.class}" << pp_identifier
    msg << pp_position if @attrs.include? KAXPositionAttribute
    msg << pp_children if @attrs.include? KAXChildrenAttribute
    msg << pp_checkbox(:enabled) if @attrs.include? KAXEnabledAttribute
    msg << pp_checkbox(:focused) if @attrs.include? KAXFocusedAttribute
    msg << '>'
  end

  ##
  # @note Since `#inspect` is often overridden by subclasses, this cannot
  #       be an alias.
  #
  # An "alias" for {#inspect}.
  #
  # @return [String]
  def to_s
    inspect
  end

  ##
  # Overriden to respond properly with regards to dynamic attribute
  # lookups, but will return false for potential implicit searches.
  def respond_to? name
    return true if lookup name, with: @attrs
    return true if lookup name, with: _parameterized_attributes
    return @attrs.include? KAXDescriptionAttribute if name == :description
    return super
  end

  ##
  # Get the center point of the element.
  #
  # @return [CGPoint]
  def to_point
    point, size = attrs [KAXPositionAttribute, KAXSizeAttribute], for: @ref
    point.center size
  end

  ##
  # Get the bounding rectangle for the element.
  #
  # @return [CGRect]
  def bounds
    CGRectMake(attrs([KAXPositionAttribute, KAXSizeAttribute], for: @ref))
  end

  ##
  # Concept borrowed from `Active Support`. It is used during implicit
  # searches to determine if searches yielded responses.
  def blank?
    false
  end

  ##
  # @todo Need to add '?' to predicate methods, but how?
  #
  # Like {#respond_to?}, this is overriden to include attribute methods.
  def methods include_super = true, include_objc_super = false
    attributes << parameterized_attributes << super
  end

  ##
  # Overridden so that equality testing would work. A hack, but the only
  # sane way I can think of to test for equivalency.
  def == other
    @ref == other.instance_variable_get(:@ref)
  end
  alias_method :eql?, :==
  alias_method :equal?, :==


  protected

  def _parameterized_attributes
    @param_attrs ||= param_attrs_for @ref
  end

  def _actions
    @actions ||= actions_for @ref
  end

  def lookup key, with: values
    value = TRANSLATOR.lookup key, with: values
    return value if values.include? value
  end

end
