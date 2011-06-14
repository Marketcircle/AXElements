##
# @abstract
#
# The abstract base class for all accessibility objects.
class AX::Element

  ##
  # @todo take a second argument of the attributes array; the attributes
  #       are already retrieved once to decide on the class type; if that
  #       can be cached and used to initialize an element, we can save a
  #       more expensive call to fetch the attributes
  #
  # @param [AXUIElementRef] element
  def initialize element
    @ref        = element
    @attributes = AX.attrs_of_element(element)
  end

  # @group Attributes

  # @return [Array<String>] cache of available attributes
  attr_reader :attributes

  # @param [Symbol] attr
  def get_attribute attr
    real_attribute = attribute_for attr
    raise ArgumentError, "#{attr} is not an attribute" unless real_attribute
    attribute(real_attribute)
  end

  ##
  # A short path when you have the exact name of the attribute you want
  # to retrieve the value of.
  #
  # This API exists for the sake of making search much faster.
  def attribute name
    AX.attr_of_element(@ref, name)
  end

  ##
  # Needed to override inherited {NSObject#description}. If you want a
  # description of the object use {#inspect} instead.
  def description
    get_attribute :description
  end

  ##
  # @todo Is it worth caching? Does it matter if it matters to cache the PID?
  #
  # Get the process identifier for the application that the element
  # belongs to.
  #
  # @return [Fixnum]
  def pid
    @pid ||= AX.pid_of_element(@ref)
  end

  # @param [Symbol] attr
  def attribute_writable? attr
    real_attribute = attribute_for attr
    raise ArgumentError, "#{attr} not found" unless real_attribute
    AX.attr_of_element_writable?(@ref, real_attribute)
  end

  ##
  # We cannot make any assumptions about the state of the program after
  # you have set a value; at least not in the general case.
  #
  # @param [String] attr an attribute constant
  # @return the value that you set is returned
  def set_attribute attr, value
    real_attribute = attribute_for attr
    raise ArgumentError, "#{attr} is not an attribute" unless real_attribute
    unless AX.attr_of_element_writable?(@ref, real_attribute)
      raise ArgumentError, "#{attr} not writable"
    end
    self.send(:attribute=, real_attribute, value)
    value
  end

  ##
  # This API exists to be consistent with {#attribute}.
  def attribute= name, value
    AX.set_attr_of_element(@ref, name, value)
  end

  # @group Parameterized Attributes

  # @return [Array<String>] available parameterized attributes
  def param_attributes
    AX.param_attrs_of_element(@ref)
  end

  ##
  # @todo Merge this into {#method_missing} and other places once I
  #       understand it more, it just adds overhead right now
  #
  # @param [Symbol] attr
  def get_param_attribute attr, param
    real_attribute = param_attribute_for attr
    raise ArgumentError, "#{attr} is not a parameterized attribute" unless real_attribute
    param_attribute(real_attribute, param)
  end

  ##
  # This API exists to be consistent with {#attribute}.
  def param_attribute name, param
    AX.param_attr_of_element(@ref, name, param)
  end

  # @group Actions

  # @return [Array<String>] cache of available actions
  def actions
    AX.actions_of_element(@ref)
  end

  ##
  # Ideally this method would return a reference to `self`, but since
  # this method inherently causes state change, the reference to `self`
  # may no longer be valid. An example of this would be pressing the
  # close button on a window.
  #
  # @param [String] name an action constant
  # @return [Boolean] true if successful
  def perform_action name
    real_action = action_for name
    raise ArgumentError, "#{name} is not an action" unless real_action
    action(real_action)
  end

  ##
  # This API exists to be consistent with {#attribute}.
  def action name
    AX.action_of_element(@ref, name)
  end

  # @group Search

  ##
  # @todo Do all camelization here before delagating so that it only has
  #       to be done once. Also is better encapsulation and consistency.
  #
  # Perform a breadth first search through the view hierarchy rooted at
  # the current element.
  #
  # See the documentation page {file:docs/Searching.markdown Searching}
  # on the details of how to search.
  #
  # @example Find the dock item for the Finder app
  #
  #   AX::DOCK.search( :application_dock_item, title:'Finder' )
  #
  # @param [Symbol,String] element_type
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search element_type, filters = nil
    type = element_type.to_s.camelize!
    meth = ((klass = type.singularize) == type) ? :find : :find_all
    Accessibility::Search.send(meth, self, klass.to_sym, (filters || {}))
  end

  ##
  # We use {#method_missing} to dynamically handle requests to lookup
  # attributes or search for elements in the view hierarchy. An attribute
  # lookup is tried first.
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
  #   window.buttons(title:'New Project', enabled?:true)
  #
  def method_missing method, *args
    attr = attribute_for method
    return attribute(attr) if attr
    return search(method, args.first) if attributes.include?(KAXChildrenAttribute)
    super
  end

  # @group Notifications

  ##
  # Register to receive a notification from an object.
  #
  # You can optionally pass a block to this method that will be given
  # an element equivalent to `self` and the name of the notification;
  # the block should return a truthy value that decides if the
  # notification received is the expected one.
  #
  # @param [String,Symbol] notif
  # @param [Float] timeout
  # @yield
  # @yieldparam [AX::Element] element
  # @yieldparam [String] notif
  # @yieldreturn [Boolean]
  # @return [Proc]
  def on_notification notif, &block
    AX.register_for_notif(@ref, notif_for(notif), &block)
  end

  # @endgroup

  ##
  # Overriden to produce cleaner output.
  def inspect
    nice_attrs = attributes.map { |name| AX.strip_prefix name }
    "\#<#{self.class} @attributes=#{nice_attrs}>"
  end

  ##
  # @todo Find out what is going wrong when I make this recursive;
  #       it is crashing MacRuby, but the backtrace shows the problem
  #       occuring in 'com.apple.HIServices' in the
  #       `_AXMIGCopyAttributeNames` function.
  #
  # A more expensive {#inspect} where we actually look up the
  # values for each attribute and format the output nicely.
  def pretty_print
    array = attributes.map do |attr|
      [AX.strip_prefix(attr), attribute(attr)]
    end
    Hash[array]
  end

  ##
  # Overriden to respond properly with regards to the dynamic
  # attribute lookups, but will return false on potential
  # search names.
  def respond_to? name
    return true if attribute_for(name)
    super
  end

  ##
  # @todo FINISH THIS METHOD
  #
  # Like {#respond_to?}, this is overriden to include attribute methods.
  # def methods include_super = false, include_objc_super = false
  #   super
  # end

  ##
  # Overridden so that equality testing would work. A hack, but the only
  # sane way I can think of to test for equivalency.
  def == other
    @ref == other.instance_variable_get(:@ref)
  end
  alias_method :eql?, :==
  alias_method :equal?, :==


  protected

  ##
  # Make a string that should match the suffix of a attribute/action
  # constant from an AX::Element object.
  def matcher name
    name = name.to_s
    name.chomp!('?')
    name.delete('_')
  end

  def notif_for name
    name  = name.to_s
    const = "KAX#{name.camelize!}Notification"
    Kernel.const_defined?(const) ? Kernel.const_get(const) : name
  end

  def attribute_for sym;       constant_for sym, attributes;       end
  def action_for sym;          constant_for sym, actions;          end
  def param_attribute_for sym; constant_for sym, param_attributes; end

  ##
  # @todo Investigate if using a regex is faster than calling
  #       caseInsensitiveCompare for the average AX constant
  #
  # Match a symbol to a attribute/action constant a suffix of an action
  # constant.
  #
  # @return [String,nil]
  def constant_for sym, array
    suffix = matcher(sym)
    array.find do |const|
      AX.strip_prefix(const).caseInsensitiveCompare(suffix) == NSOrderedSame
    end
  end

end
