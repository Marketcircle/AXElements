# -*- coding: utf-8 -*-

require 'ax_elements/macruby_extensions'
require 'ax_elements/vendor/inflector'
require 'accessibility/core'
require 'accessibility/factory'

require 'ax/element/inspector'
require 'ax/element/errors'
require 'ax/element/enumerators'
require 'ax/element/qualifier'

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
  include Accessibility::Core
  include Accessibility::PPInspector
  extend  Accessibility::Factory


  # @param [AXUIElementRef]
  # @param [Array<String>]
  def initialize ref, attrs
    @ref        = ref
    @attributes = attrs
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
    @attributes.map { |x| TRANSLATOR[x].underscore.to_sym }
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
    real_attr = attribute_for attr
    raise Accessibility::LookupFailure.new(self, attr) unless real_attr
    self.class.attribute real_attr, for: @ref
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
    real_attr = attribute_for attr
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
  #   element.writable_attr? :size  # => true
  #   element.writable_attr? :value # => false
  #
  # @param [Symbol] attr
  def writable_attr? attr
    real_attr = attribute_for attr
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
    unless writable_attr? attr
      raise NoMethodError, "#{attr} is read-only for #{inspect}"
    end
    real_attr = attribute_for attr
    value     = value.to_axvalue
    set real_attr, to: value, for: @ref
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
  def param_attributes
    _param_attributes.map { |x| TRANSLATOR[x].underscore.to_sym }
  end

  ##
  # Get the value for a parameterized attribute.
  #
  # @example
  #
  #  text_field.attribute :string_for_range, for_param: (2..8).relative_to(10)
  #
  # @param [Symbol]
  def attribute attr, for_param: param
    real_attr = param_attribute_for attr
    raise Accessibility::LookupFailure.new(self, attr) unless real_attr
    param = param.to_axvalue
    self.class.param_attribute param, for_param: param, for: @ref
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
    _actions.map { |x| TRANSLATOR[x].underscore.to_sym }
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
  # @param [String] name an action constant
  # @return [Boolean] true if successful
  def perform name
    real_action = action_for name
    raise Accessibility::LookupFailure.new(self, name) unless real_action
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
  # @param [#to_s] kind
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search kind, filters = {}
    kind      = kind.camelize
    klass     = kind.singularize
    search    = klass == kind ? :find : :find_all
    qualifier = Accessibility::Qualifier.new(klass, filters)
    tree      = Accessibility::Enumerator::BreadthFirst.new(self)

    tree.send(search) { |element| qualifier.qualifies? element }
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
    if attr = attribute_for(method)
      return self.class.attribute attr, for: @ref

    elsif attr = param_attribute_for(method)
      return self.class.param_attribute attr, for_param: args.first, for: @ref

    elsif @attributes.include? KAXChildrenAttribute
      result = search method, *args
      return result unless result.blank?
      raise Accessibility::SearchFailure.new(self, method, args.first)

    else
      super

    end
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
  # @yieldparam [AX::Element]
  # @yieldparam [String]
  # @yieldreturn [Boolean]
  # @return [Array(String,self)] the notification/element pair
  def on_notification name, &block
    notif = notif_for name
    register_to_receive notif, from: @ref do |sender, notification|
      element = self.class.process sender
      block ? block.call(element, notification) : true
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
    msg << pp_position if @attributes.include? KAXPositionAttribute
    msg << pp_children if @attributes.include? KAXChildrenAttribute
    msg << pp_checkbox(:enabled) if @attributes.include? KAXEnabledAttribute
    msg << pp_checkbox(:focused) if @attributes.include? KAXFocusedAttribute
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
    return true if attribute_for name
    return true if param_attribute_for name
    return @attributes.include? KAXDescriptionAttribute if name == :description
    return super
  end
  alias_method :responds_to?, :respond_to?

  ##
  # Get the center point of the element.
  #
  # @return [CGPoint]
  def to_point
    attribute(:position).center(attribute :size)
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
    attributes << param_attributes << super
  end

  ##
  # Overridden so that equality testing would work. A hack, but the only
  # sane way I can think of to test for equivalency.
  def == other
    @ref == other.instance_variable_get(:@ref)
  end
  alias_method :eql?, :==
  alias_method :equal?, :==

  # @todo Do we need to override #=== as well?


  protected

  def _param_attributes
    @param_attributes ||= param_attrs_for @ref
  end

  def _actions
    @actions ||= actions_for @ref
  end

  ##
  # Try to turn an arbitrary symbol into a notification constant, and
  # then get the value of the constant.
  #
  # @param [#to_s]
  # @return [String]
  def notif_for name
    name  = name.to_s
    const = "KAX#{name.camelize}Notification"
    Object.const_defined?(const) ? Object.const_get(const) : name
  end

  ##
  # Find the constant value for the given symbol. If nothing is found
  # then `nil` will be returned.
  #
  # @param [Symbol]
  # @return [String,nil]
  def attribute_for sym
    @@array = @attributes
    val     = @@const_map[sym]
    val if @attributes.include? val
  end

  # (see #attribute_for)
  def action_for sym
    @@array = _actions
    val     = @@const_map[sym]
    val if _actions.include? val
  end

  # (see #attribute_for)
  def param_attribute_for sym
    @@array = _param_attributes
    val     = @@const_map[sym]
    val if _param_attributes.include? val
  end

  ##
  # @todo Move this to {Accessibility::Translator}
  #
  # Memoized map for symbols to constants used for attribute/action
  # lookups.
  #
  # @return [Hash{Symbol=>String}]
  @@const_map = Hash.new do |hash,key|
    @@array.each { |x| hash[TRANSLATOR[x].underscore.to_sym] = x }
    if hash.has_key? key
      hash[key]
    else # try other cases of transformations
      real_key = key.chomp('?').to_sym
      hash.has_key?(real_key) ? hash[key] = hash[real_key] : nil
    end
  end

  # preload the table
  @@const_map[:id] = KAXIdentifierAttribute

  TRANSLATOR = Accessibility::Translator.instance

end
