module AX

##
# @abstract
#
# The abstract base class for all accessibility objects.
class Element

  include Traits::Clicking
  include Traits::Notifications

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

  ##
  # @todo need a method for getting method names from from things
  #       refactored from #method_missing
  #
  # @param [String] attr
  # @return [Boolean]
  def attribute_writable? attr
    ptr = Pointer.new(:id)
    error_code = AXUIElementElementIsAttributeSettable( @ref, attr, ptr )
    log(error_code, attr)
    ptr[0]
  end

  # @param [String] attr an attribute constant
  # @return [Object,nil]
  def attribute attr
    result_ptr = Pointer.new(:id)
    error_code = AXUIElementCopyAttributeValue( @ref, attr, result_ptr )
    log(error_code, attr)
    result_ptr[0]
  end

  # @return [AX::Element]
  def element_attribute value
    AX.make_element( value )
  end

  # @return [Array,nil]
  def array_attribute value
    if value.empty? || (ATTR_MASSAGERS[CFGetTypeID(value.first)] == 1)
      value
    else
      value.map { |element| element_attribute(element) }
    end
  end

  # @return [Boxed,nil]
  def boxed_attribute value
    return nil unless value
    box = AXValueGetType( value )
    ptr = Pointer.new( AXBoxType[box].type )
    AXValueGetValue( value, box, ptr )
    ptr[0]
  end

  # Like the {#perform_action} method, we cannot make any assumptions
  # about the state of the program after you have set a value; at
  # least not in the general case. So, the best we can do here is
  # return true if there were no issues.
  # @param [String] attr
  # @return [Boolean] true if successful, otherwise false
  def set_attribute_with_value attr, value
    error_code = AXUIElementSetAttributeValue( @ref, attr, value )
    log( error_code, [attr, value] ) == 0
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
    error_code = AXUIElementPerformAction( @ref, action_name )
    log( error_code, action_name ) == 0
  end

  # @todo THESE STILL NEED TO BE DEALT WITH
  @@setter_methods = {
    get_focus:[:set_attribute_with_value, NSAccessibilityFocusedAttribute, true],
    :value= =>[:set_attribute_with_value, NSAccessibilityValueAttribute],
  }

  ATTR_MASSAGERS = []
  ATTR_MASSAGERS[AXUIElementGetTypeID()] = :element_attribute
  ATTR_MASSAGERS[CFArrayGetTypeID()]     = :array_attribute
  ATTR_MASSAGERS[AXValueGetTypeID()]     = :boxed_attribute

  ##
  # @todo replace lookup table with name mangling using
  #  ActiveSupport::Inflector to mangle the name (pre_mangle _ui_),
  #  and then introspect the object to find out if it needs to be
  #  wrapped and how. this will replace the need for all the attribute
  #  lookups. the actions will be tricky, but we will have
  #  separate the attributes from the actions and check attributes
  #  first and then actions
  #  the setters will have to be done in such a way that #respond_to?
  #  will not return true when it doesn't exist
  # @todo allow regex matching when filtering string attributes
  # @note Some attribute names don't map consistently from Apple's
  #  documentation because it would have caused a clash with the two
  #  systems used for attribute lookup and searching/filtering.
  #
  # We use {#method missing} to dynamically handle requests to lookup
  # attributes and to dynamically search for elements in the view
  # hierarchy. Everything that is not a convenience method is routed
  # through here to figure things out for you dynamically.
  #
  # Since this method does two types of dynamic lookup, one has to take
  # priority over the other. Attribute lookups come first, and if that
  # fails a search through the hierarchy will begin.
  #
  # When you are looking up an attribute, this method will first make
  # sure that the current element has the required attribute, then it
  # will try to map the method name to an actual attribute name (listed
  # in {.method_map}) in order to call a lower level method (which in
  # turn calls the actual CoreFoundation API).
  #
  # Should the attribute lookup fail, the method will then try search
  # for an element that is a descendant of the current element by way of
  # a breadth first search through the view hierarchy subtree rooted at
  # the current node.
  #
  # There are two features of the search that are important with regards
  # results of the search: pluralization and filtering.
  #
  # Pluralization is simply when an 's' is appended to the method call
  # causing the lookup to assume you wanted every element in the view
  # hierarchy that meets the filtering criteria. This causes the lookup
  # to be very slow (~1 second) and is meant more for prototying tests
  # and debugging broken tests. If you do not pluralize, then the first
  # element that meets all the filtering criteria will be returned.
  #
  # Filtering is the important part of a lookup. There is one default
  # filter which filters based on the class of the element, and the class
  # name is taken from method name that triggered {#method_missing}. Other
  # filtering criteria is optional, but often helpful in finding a
  # specific element. Right now the only types of filtering criteria that
  # work are attribute filters, which lookup attributes on the element
  # being inspected and compare them to an expected value. You can attach
  # as many attribute filters as you want.
  #
  # @example Attribute lookup of another element
  #  mail   = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  #  window = mail.focused_window
  # @example Attribute lookup of element properties
  #  window.title
  # @example Simple single element lookup
  #  window.button # => You want the first Button that is found
  # @example Simple multi-element lookup
  #  window.text_fields # => You want all the TextField objects found
  # @example Additional filters for a single element lookup
  #  window.button(title:'Log In') # => First Button with a title of 'Log In'
  # @example Additional filters for a multi-element lookup
  #  window.buttons(title:'New Project')
  # @example Contrived multi-element lookup
  #  window.buttons(title:'New Project', enabled?:true)
  # @raise NoMethodError
  def method_missing method, *args

    # Bascially:
    # attribute_lookup || action_lookup || element_search || super

    attr = attribute_for_symbol(method)
    if attr
      ret = self.attribute(attr)
      id  = ATTR_MASSAGERS[CFGetTypeID(ret)]
      return (id ? self.send(id, ret) : ret)
    end

    action = action_for_symbol(method)
    return self.perform_action(action) if action

    # NOW WE TRY TO DO A SEARCH

    # check to avoid an infinite loop
    if attributes.index(KAXChildrenAttribute)
      elements       = self.children # seed the search array
      search_results = []
      filters        = args[0] || {}
      class_const    = method.to_s.camelize!

      until elements.empty?
        element          = elements.shift
        primary_filter ||= AX.plural_const_get(class_const)

        elements.concat(element.children) if element.attributes.include?(KAXChildrenAttribute)

        next unless element.class == primary_filter
        next if filters.find { |filter| element.send(filter[0]) != filter[1] }

        return element unless method.to_s[-1] == 's'
        search_results << element
      end

      return search_results if method.to_s[-1] == 's'
      return search_results.first
    end

    AX.log.debug "##{method} attr doesn't exist and this #{self.class} doesn't have children"
    super
  end


  ##
  # Needed to override inherited {#raise} so that the raise action still
  # works, but in such a way that the original {#raise} still works.
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
  # Method is overriden to produce cleaner output.
  def inspect
    nice_methods = (attributes + actions).map { |name|
      name.sub(AX.accessibility_prefix) { $1 }
    }
    "\#<#{self.class} @methods=#{nice_methods}>"
  end

  ##
  # @todo finish this method
  #
  # A more expensive {#inspect} where we actually look up the
  # values for each attribute and formate the output nicely.
  def pretty_print
    nice_methods = (attributes + actions).map { |name|
      name.sub(AX.accessibility_prefix) { $1 }
    }
    "\#<#{self.class} @methods=#{nice_methods}>"
  end

  ##
  # This helps a bit with regards to the dynamic methods.
  # However, it does not work on search names.
  #
  # @param [Symbol] name
  def respond_to? name
    matcher = /#{name.to_s.gsub(/_|\?$/, '')}$/i
    for method in (attributes + actions)
      return true if method.match(matcher)
    end
    super
  end


  protected

  # @return [String,nil]
  def attribute_for_symbol sym
    matcher = AX.matcher(sym)
    matches = []
    for attr in attributes
      matches << attr if attr.match(matcher)
    end
    unless matches.empty?
      matches.sort_by(&:length) if matches.size > 1
      matches.first
    end
  end

  # @return [String,nil]
  def action_for_symbol sym
    matcher = AX.matcher(sym)
    for action in actions
      return action if action.match(matcher)
    end
  end

  ##
  # This array is order-sensitive, which is why there is a
  # nil object at index 0.
  #
  # @return [Class,nil]
  AXBoxType = [ nil, CGPoint, CGSize, CGRect, CFRange ]

  ##
  # @todo find out how to get a list of constants (dietrb source)
  #
  # A mapping of the AXError constants to human readable strings.
  # @return [Hash{Fixnum => String}]
  AXError = {
    KAXErrorFailure                           => 'Generic Failure',
    KAXErrorIllegalArgument                   => 'Illegal Argument',
    KAXErrorInvalidUIElement                  => 'Invalid UI Element',
    KAXErrorInvalidUIElementObserver          => 'Invalid UI Element Observer',
    KAXErrorCannotComplete                    => 'Cannot Complete',
    KAXErrorAttributeUnsupported              => 'Attribute Unsupported',
    KAXErrorActionUnsupported                 => 'Action Unsupported',
    KAXErrorNotificationUnsupported           => 'Notification Unsupported',
    KAXErrorNotImplemented                    => 'Not Implemented',
    KAXErrorNotificationAlreadyRegistered     => 'Notification Already Registered',
    KAXErrorNotificationNotRegistered         => 'Notification Not Registered',
    KAXErrorAPIDisabled                       => 'API Disabled',
    KAXErrorNoValue                           => 'No Value',
    KAXErrorParameterizedAttributeUnsupported => 'Parameterized Attribute Unsupported',
    KAXErrorNotEnoughPrecision                => 'Not Enough Precision',
  }

  ##
  # @todo print view hierarchy using {#pretty_print}
  #
  # Uses the call stack and error code to log a message that might be helpful
  # in debugging.
  #
  # @param [Fixnum] error_code an AXError value
  # @param [#to_s] method_args an AXError value
  # @return [Fixnum] the error code that was passed to this method
  def log error_code, method_args = 'unspecified method'
    return error_code if error_code.zero?
    error = AXError[error_code] || 'UNKNOWN ERROR CODE'
    AX.log.warn "[#{error} (#{error_code})] while trying #{method_args} on a #{self.role}"
    AX.log.info "Attributes and actions that were available: #{self.methods.inspect}"
    AX.log.debug "Backtrace: #{caller.description}"
    error_code
  end
end
end
