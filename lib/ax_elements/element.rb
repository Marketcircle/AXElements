# -*- coding: utf-8 -*-

require 'active_support/inflector'
require 'ax_elements/inspector'
require 'ax_elements/accessibility'

##
# @abstract
#
# The abstract base class for all accessibility objects.
class AX::Element
  include Accessibility::PPInspector

  ##
  # Raised when a lookup fails
  class LookupFailure < ArgumentError
    def initialize element, name
      super "#{name} was not found for #{element.inspect}"
    end
  end

  ##
  # Raised when trying to set an attribute that cannot be written
  class ReadOnlyAttribute < NoMethodError
    def initialize element, name
      super "#{name} is a read only attribute for #{element.inspect}"
    end
  end

  ##
  # Raised when an implicit search fails
  class SearchFailure < NoMethodError
    def initialize searcher, searchee, filters
      path       = Accessibility.path(searcher).map! { |x| x.inspect }
      pp_filters = (filters || {}).map do |key, value|
        "#{key}: #{value.inspect}"
      end.join(', ')
      msg  = "Could not find `#{searchee}"
      msg << "(#{pp_filters})" unless pp_filters.empty?
      msg << "` as a child of #{searcher.class}"
      msg << "\nElement Path:\n\t" << path.join("\n\t")
      super msg
    end
  end

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
  # @return [Array<String>]
  attr_reader :attributes

  ##
  # Get the value of an attribute.
  #
  # @example
  #
  #   element.attribute :position # => "#<CGPoint x=123.0 y=456.0>"
  #
  # @param [Symbol]
  def attribute attr
    real_attr = attribute_for attr
    raise LookupFailure.new(self, attr) unless real_attr
    self.class.attribute_for @ref, real_attr
  end

  ##
  # Needed to override inherited `NSObject#description`. If you want a
  # description of the object use {#inspect} instead.
  def description
    attribute :description
  end

  ##
  # You can use this method to find out the `#size` of an array that is
  # an attribute of the element. This exists because it is _much_ more
  # efficient to find out how many `children` exist using this API instead
  # of getting the children array and asking for the size.
  #
  # @example
  #
  #   button.size_of :children # => 0
  #   window.size_of :children # => 16
  #
  # @param [Symbol]
  # @return [Number]
  def size_of attr
    real_attr = attribute_for attr
    raise LookupFailure.new(self, attr) unless real_attr
    AX.attr_count_of_element @ref, real_attr
  end

  ##
  # Get the process identifier for the application that the element
  # belongs to.
  #
  # @return [Fixnum]
  def pid
    @pid ||= AX.pid_of_element @ref
  end

  ##
  # Check whether or not an attribute is writable.
  #
  # @param [Symbol] attr
  def attribute_writable? attr
    real_attribute = attribute_for attr
    raise LookupFailure.new(self, attr) unless real_attribute
    AX.attr_of_element_writable? @ref, real_attribute
  end

  ##
  # @note Due to the way thot `Boxed` objects are taken care of, you
  #       cannot pass tuples in place of the `Boxed` object. This may
  #       change in the future.
  #
  # Set a writable attribute on the element to the given value.
  #
  # @param [String] attr an attribute constant
  # @return the value that you were setting is returned
  def set_attribute attr, value
    raise ReadOnlyAttribute.new(self, attr) unless attribute_writable? attr
    real_attribute = attribute_for attr
    value = value.to_axvalue if value.kind_of? Boxed
    AX.set_attr_of_element @ref, real_attribute, value
    value
  end

  # @group Parameterized Attributes

  ##
  # List of available parameterized attributes
  #
  # @return [Array<String>]
  def param_attributes
    @param_attributes ||= AX.param_attrs_of_element @ref
  end

  ##
  # @note Due to the way thot `Boxed` objects are taken care of, you
  #       cannot pass tuples in place of the `Boxed` object. This may
  #       change in the future.
  #
  # Get the value for a parameterized attribute.
  #
  # @param [Symbol]
  def param_attribute attr, param
    real_attr = param_attribute_for attr
    raise LookupFailure.new(self, attr) unless real_attr
    param = param.to_axvalue if param.kind_of? Boxed
    self.class.param_attribute_for @ref, real_attr, param
  end

  # @group Actions

  ##
  # List of available actions.
  #
  # @return [Array<String>]
  def actions
    @actions ||= AX.actions_of_element @ref
  end

  ##
  # @note Ideally this method would return a reference to `self`, but
  #       since intrinsically  causes state change in the app being
  #       manipulate, the reference to `self` may no longer be valid.
  #       An example of this would be pressing the close button on a
  #       window.
  #
  # Tell an object to trigger an action without actually performing
  # the action.
  #
  # For instance, you can tell a button to call the same method that
  # would be called when pressing a button, except that the mouse will
  # not move over to the button to press it, nor will the keyboard be
  # used.
  #
  # @example
  #
  #   element.perform_action :press # => true
  #
  # @param [String] name an action constant
  # @return [Boolean] true if successful
  def perform_action name
    real_action = action_for name
    raise LookupFailure.new(self, name) unless real_action
    AX.action_of_element @ref, real_action
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
    tree      = Accessibility::BFEnumerator.new(self)

    tree.send(search) { |element| qualifier.qualifies? element }
  end

  ##
  # We use {#method_missing} to dynamically handle requests to lookup
  # attributes or search for elements in the view hierarchy. An attribute
  # lookup is always tried first, followed by a parameterized attribute
  # lookup, and then finally a search.
  #
  # Failing both lookups, this method calls `super`.
  #
  # @example Attribute lookup of an element
  #
  #   mail   = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  #   window = mail.focused_window
  #
  # @example Attribute lookup of an element property
  #
  #   window.title
  #
  # @example Simple single element search
  #
  #   window.button # => You want the first Button that is found
  #
  # @example Simple multi-element search
  #
  #   window.buttons # => You want all the Button objects found
  #
  # @example Filters for a single element search
  #
  #   window.button(title:'Log In') # => First Button with a title of 'Log In'
  #
  # @example Contrived multi-element search with filtering
  #
  #   window.buttons(title:'New Project', enabled:true)
  #
  # @example Attribute and element search failure
  #
  #   window.application # => SearchFailure is raised
  #
  # @example Parameterized Attribute lookup
  #
  #   text = window.title_ui_element
  #   text.string_for_range(CFRange.new(0, 1))
  #
  def method_missing method, *args
    if attr = attribute_for(method)
      return self.class.attribute_for(@ref, attr)

    elsif attr = param_attribute_for(method)
      return self.class.param_attribute_for(@ref, attr, args.first)

    elsif attributes.include? KAXChildrenAttribute
      result = search method, *args
      return result unless result.blank?
      raise SearchFailure.new(self, method, args.first)

    else
      super

    end
  end

  # @group Notifications

  ##
  # Register to receive a notification from the object.
  #
  # You can optionally pass a block to this method that will be given
  # an element equivalent to `self` and the name of the notification;
  # the block should return a boolean value that decides if the
  # notification received is the expected one.
  #
  # @param [String,Symbol]
  # @param [Float] timeout
  # @yieldparam [AX::Element] element
  # @yieldparam [String] notif
  # @yieldreturn [Boolean]
  # @return [Array(self,String)] an (element, notification) pair
  def on_notification notif, &block
    AX.register_for_notif @ref, notif_for(notif) do |element, notif|
      element = self.class.process element
      block ? block.call(element, notif) : true
    end
  end

  # @endgroup

  ##
  # Overriden to produce cleaner output.
  #
  # @return [String]
  def inspect
    msg  = "#<#{self.class}" << pp_identifier
    msg << pp_position if attributes.include? KAXPositionAttribute
    msg << pp_children if attributes.include? KAXChildrenAttribute
    msg << pp_checkbox(:enabled) if attributes.include? KAXEnabledAttribute
    msg << pp_checkbox(:focused) if attributes.include? KAXFocusedAttribute
    msg << '>'
  end

  ##
  # Overriden to respond properly with regards to the ydnamic attribute
  # lookups, but will return false for potential implicit searches.
  def respond_to? name
    return true if attribute_for name
    return true if param_attribute_for name
    return attributes.include? KAXDescriptionAttribute if name == :description
    return super
  end

  ##
  # Get the center point of the element.
  #
  # @return [CGPoint]
  def to_point
    attribute(:position).center(attribute :size)
  end

  ##
  # Used during implicit search to determine if searches yielded
  # responses.
  def blank?
    false
  end

  ##
  # @todo Need to add '?' to predicate methods, but how?
  #
  # Like {#respond_to?}, this is overriden to include attribute methods.
  def methods include_super = true, include_objc_super = false
    names = attributes.map { |x| self.class.strip_prefix(x).underscore.to_sym }
    names.concat super
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

  ##
  # Try to turn an arbitrary symbol into notification constant, and
  # then get the value of the constant.
  #
  # @param [Symbol,String]
  # @return [String]
  def notif_for name
    name  = name.to_s
    const = "KAX#{name.camelize}Notification"
    Kernel.const_defined?(const) ? Kernel.const_get(const) : name
  end

  ##
  # Find the constant value for the given symbol. If nothing is found
  # then `nil` will be returned.
  #
  # @param [Symbol]
  # @return [String,nil]
  def attribute_for sym
    @@array = attributes
    val     = @@const_map[sym]
    val if attributes.include? val
  end

  # (see #attribute_for)
  def action_for sym
    @@array = actions
    val     = @@const_map[sym]
    val if actions.include? val
  end

  # (see #attribute_for)
  def param_attribute_for sym
    @@array = param_attributes
    val     = @@const_map[sym]
    val if param_attributes.include? val
  end

  ##
  # @private
  #
  # Memoized map for symbols to constants used for attribute/action
  # lookups.
  #
  # @return [Hash{Symbol=>String}]
  @@const_map = Hash.new do |hash,key|
    @@array.map { |x| hash[strip_prefix(x).underscore.to_sym] = x }
    if hash.has_key? key
      hash[key]
    else # try other cases of transformations
      real_key = key.chomp('?').to_sym
      hash.has_key?(real_key) ? hash[key] = hash[real_key] : nil
    end
  end


  class << self

    ##
    # Retrieve and process the value of the given attribute for the
    # given element reference.
    #
    # @param [AXUIElementRef]
    # @param [String]
    def attribute_for ref, attr
      process AX.attr_of_element(ref, attr)
    end

    ##
    # Retrieve and process the value of the given parameterized attribute
    # for the parameter and given element reference.
    #
    # @param [AXUIElementRef]
    # @param [String]
    def param_attribute_for ref, attr, param
      param = param.to_axvalue if param.kind_of? Boxed
      process AX.param_attr_of_element(ref, attr, param)
    end

    ##
    # Meant for taking a return value from {AX.attr_of_element} and,
    # if required, converts the data to something more usable.
    #
    # Generally, used to process an `AXValue` into a `CGPoint` or an
    # `AXUIElementRef` into some kind of {AX::Element} object.
    def process value
      return nil if value.nil?
      id = ATTR_MASSAGERS[CFGetTypeID(value)]
      id ? self.send(id, value) : value
    end

    ##
    # @note In the case of a predicate name, this will strip the 'Is'
    #       part of the name if it is present
    #
    # Takes an accessibility constant and returns a new string with the
    # namespace prefix removed.
    #
    # @example
    #
    #   AX.strip_prefix 'AXTitle'                    # => 'Title'
    #   AX.strip_prefix 'AXIsApplicationEnabled'     # => 'ApplicationEnabled'
    #   AX.strip_prefix 'MCAXEnabled'                # => 'Enabled'
    #   AX.strip_prefix KAXWindowCreatedNotification # => 'WindowCreated'
    #   AX.strip_prefix NSAccessibilityButtonRole    # => 'Button'
    #
    # @param [String] const
    # @return [String]
    def strip_prefix const
      const.sub /^[A-Z]*?AX(?:Is)?/, ::EMPTY_STRING
    end


    private

    ##
    # @private
    #
    # Map Core Foundation type ID numbers to methods. This is how
    # double dispatch is used to massage low level data into
    # something nice.
    #
    # Indexes are looked up and added to the array at runtime in
    # case values change in the future.
    #
    # @return [Array<Symbol>]
    ATTR_MASSAGERS = []
    ATTR_MASSAGERS[AXUIElementGetTypeID()] = :process_element
    ATTR_MASSAGERS[CFArrayGetTypeID()]     = :process_array
    ATTR_MASSAGERS[AXValueGetTypeID()]     = :process_box

    ##
    # @todo Refactor this pipeline so that we can pass the attributes we look
    #       up to the initializer for Element, and also so we can avoid some
    #       other duplicated work.
    #
    # Takes an AXUIElementRef and gives you some kind of accessibility object.
    #
    # @param [AXUIElementRef]
    # @return [AX::Element]
    def process_element ref
      attrs = AX.attrs_of_element ref
      role  = AX.role_for(ref, attrs).map! { |x| strip_prefix x }
      determine_class_for(role).new(ref, attrs)
    end

    ##
    # Like `#const_get` except that if the class does not exist yet then
    # it will assume the constant belongs to a class and creates the class
    # for you.
    #
    # @param [Array<String>] const the value you want as a constant
    # @return [Class] a reference to the class being looked up
    def determine_class_for names
      klass = names.first
      if AX.const_defined? klass, false
        AX.const_get klass
      else
        create_class *names
      end
    end

    ##
    # Creates new class at run time and puts it into the {AX} namespace.
    #
    # @param [String,Symbol] name
    # @param [String,Symbol] superklass
    # @return [Class]
    def create_class name, superklass = :Element
      real_superklass = determine_class_for [superklass]
      klass = Class.new real_superklass
      AX.const_set name, klass
    end

    ##
    # @todo Consider mapping in all cases to avoid returning a CFArray
    #
    # We assume a homogeneous array and only massage element arrays right now.
    #
    # @return [Array]
    def process_array vals
      return vals if vals.empty? || !ATTR_MASSAGERS[CFGetTypeID(vals.first)]
      vals.map { |val| process_element val }
    end

    ##
    # Extract the stuct contained in an `AXValueRef`.
    #
    # @param [AXValueRef] value
    # @return [Boxed]
    def process_box value
      box_type = AXValueGetType(value)
      ptr      = Pointer.new BOX_TYPES[box_type]
      AXValueGetValue(value, box_type, ptr)
      ptr[0]
    end

    ##
    # @private
    #
    # Map of type encodings used for wrapping structs when coming from
    # an `AXValueRef`.
    #
    # The list is order sensitive, which is why we unshift nil, but
    # should probably be more rigorously defined at runtime.
    #
    # @return [String,nil]
    BOX_TYPES = [CGPoint, CGSize, CGRect, CFRange].map! { |x| x.type }.unshift(nil)

  end
end

require 'ax_elements/elements/application'
require 'ax_elements/elements/systemwide'
require 'ax_elements/elements/row'
require 'ax_elements/elements/button'
require 'ax_elements/elements/static_text'
require 'ax_elements/elements/radio_button'
