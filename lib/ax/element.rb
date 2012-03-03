# -*- coding: utf-8 -*-

require 'ax_elements/macruby_extensions'
require 'ax_elements/vendor/inflector'
require 'accessibility/enumerators'
require 'accessibility/qualifier'
require 'accessibility/errors'
require 'accessibility/pp_inspector'
require 'accessibility/factory'


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

  ##
  # Used internally by {Accessibility::Factory} for initializing with
  # attributes instead of fetching the a second time. This is for
  # performance reasons. If you have not already fetched the attributes
  # for a reference then you should initialize normally.
  #
  # @param [AXUIElementRef]
  # @param [Array<String>]
  def self.new ref, with: attrs
    o = allocate
    o.init ref, attrs
    o
  end

  # @param [AXUIElementRef]
  # @param [Array<String>]
  def init ref, attrs
    @ref   = ref
    @attrs = attrs
  end

  # @param [AXUIElementRef]
  def initialize ref
    @ref   = ref
    @attrs = attrs_for ref
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
  # @todo Consider returning `nil` if the element does not have
  #       the given attribute.
  #
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
    if method[-1] == EQUALS
      return set(method.chomp(EQUALS), to: args.first)
    end

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

  def notifs
    @notifs ||= {}
  end

  ##
  # Register to receive notification of the given event being completed
  # by the given element.
  #
  # {file:docs/Notifications.markdown Notifications} are a way to put
  # non-polling delays into your scripts.
  #
  # Use this method to register to be notified of the specified event in
  # an application.
  #
  # The block is optional. The block will be given the sender of the
  # notification, which will almost always be `self`, and also the name
  # of the notification being received. The block should return a
  # boolean value that decides if the notification received is the
  # expected one.
  #
  # @example
  #
  #   on_notification(:window_created) { |sender|
  #     puts "#{sender.inspect} sent the ':window_created' notification"
  #     true
  #   }
  #
  # @param [#to_s] notif the name of the notification
  # @yield Validate the notification; the block should return truthy if
  #        the notification received is the expected one and the script can
  #        stop waiting, otherwise should return falsy.
  # @yieldparam [String] notif the name of the notification
  # @yieldparam [AXUIElementRef] element the element that sent the notification
  # @yieldreturn [Boolean]
  # @return [Array(Observer, String, CFRunLoopSource)]
  def on_notification name, &block
    notif    = TRANSLATOR.guess_notification_for name
    observer = observer_for self.pid, &notif_callback_for(&block)
    source   = run_loop_source_for observer
    register observer, to_receive: notif, from: @ref
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
    notifs[name] = [observer, notif, source]
  end

  def unregister_notification name
    unless notifs.has_key? name
      raise ArgumentError, "You have no registrations for #{name}"
    end
    _unregister_notification *notifs.delete(name)
  end

  ##
  # Cancel _all_ notification registrations for this object. Simple and
  # clean, but a blunt tool at best. This will have to do for the time
  # being...
  #
  # @return [nil]
  def unregister_all
    notifs.keys.each do |notif|
      unregister_notification notif
    end
    nil
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
    return true if lookup name.chomp(EQUALS).to_sym, with: @attrs
    return true if lookup name, with: _parameterized_attributes
    return @attrs.include? KAXDescriptionAttribute if name == :description
    return super
  end

  ##
  # Get the center point of the element.
  #
  # @return [CGPoint]
  def to_point
    point = attr KAXPositionAttribute, for: @ref
    size  = attr KAXSizeAttribute,     for: @ref
    unwrap(point).center unwrap(size)
  end

  ##
  # Get the bounding rectangle for the element.
  #
  # @return [CGRect]
  def bounds
    point = attr KAXPositionAttribute, for: @ref
    size  = attr KAXSizeAttribute,     for: @ref
    CGRectMake(*unwrap(point), *unwrap(size))
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
    attributes.concat(parameterized_attributes).concat(super)
  end

  ##
  # Overridden so that equality testing would work. A hack, but the only
  # sane way I can think of to test for equivalency.
  def == other
    @ref == other.instance_variable_get(:@ref)
  end
  alias_method :eql?, :==
  alias_method :equal?, :==


  private

  ##
  # @private
  #
  # Performance hack.
  #
  # @return [String]
  EQUALS = '='

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

  def notif_callback_for &block
    # we are ignoring the context pointer since this is OO
    Proc.new do |observer, sender, notif, _|
      break unless block.call(process sender) if block
      _unregister_notification observer, notif, run_loop_source_for(observer)
      CFRunLoopStop(CFRunLoopGetCurrent())
    end
  end

  ##
  # @todo What are the implications of removing the run loop source?
  #       Taking it out would clobber other notifications that are using
  #       the same source, so we would have to check if we can remove it.
  #
  def _unregister_notification observer, notif, source
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, KCFRunLoopDefaultMode)
    unregister observer, from_receiving: notif, from: @ref
  end

end
