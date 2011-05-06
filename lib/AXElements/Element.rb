module AX

##
# @abstract
# @todo A method to test for equivalency
#
# The abstract base class for all accessibility objects.
class Element

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
  # Needed to override inherited {NSObject#description}. If you want a
  # description of the object use {#inspect} instead.
  def description
    get_attribute :description
  end

  ##
  # Get the process identifier for the application that the element
  # belongs to.
  #
  # @return [Fixnum]
  def pid
    @pid ||= AX.pid_of_element( @ref )
  end

  ##
  # A short path when you have the exact name of the attribute you want
  # to retrieve the value of.
  #
  # This API exists for the sake of making search much faster.
  def attribute name
    AX.attr_of_element( @ref, name )
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
    AX.set_attr_of_element( @ref, name, value )
  end

  # @group Parameterized Attributes

  # @return [Array<String>] cache of available actions
  def param_attributes
    AX.param_attrs_of_element(@ref)
  end

  ##
  # @todo merge this into {#method_missing} other places once I understand
  #       it more, right now it would just add a lot of overhead
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
    AX.param_attr_of_element( @ref, name, param )
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
    AX.action_of_element( @ref, name )
  end

  # @group Search

  ##
  # @todo allow regex matching when filtering string attributes
  # @todo decide whether plural or singular search before entering
  #       the main loop
  # @todo make search much faster by not wrapping child classes
  # @todo refactor searching, perhaps make an iterator
  # @todo consider using the rails inflector for pluralization checking
  # @todo this method should be moved to its own class (Strategy Pattern?)
  #
  # Perform a breadth first search through the view hierarchy rooted at
  # the current element.
  #
  # See the documentation page [Searching](../file/docs/Searching.markdown)
  # on the details of how to search.
  #
  # @example Find the dock item for the Finder app
  #  AX::DOCK.search( :application_dock_item, title: 'Finder' )
  #
  # @param [Symbol,String] element_type
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search element_type, filters = {}
    klass    = element_type.to_s.camelize!
    method   = klass.chomp!('s') ? :find_all : :find
    searcher = Accessibility::Search.new(self)
    searcher.send(method, klass, (filters || {}))
  end

  ##
  # @todo search param attributes
  #
  # We use {#method_missing} to dynamically handle requests to, in the
  # following order, lookup attributes, or search for elements in the
  # view hierarchy.
  #
  # Failing both lookups, this method calls `super`.
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
    attr = attribute_for method
    return attribute(attr) if attr
    return search(method, args.first) if attributes.include?(KAXChildrenAttribute)
    super
  end

  # @group Notifications

  ##
  # @todo Need to provide a nice interface for taking notif names
  #       (i.e. `:window_created` instead of `KAXWindowCreatedNotification`)
  #
  # @yield
  # @yieldreturn [Boolean]
  #
  # @param [String] notif
  # @param [Float] timeout
  def on_notification notif, &block
    real_notif = notif_for(notif)
    raise ArgumentError, "#{notif} is not a notification constant" unless real_notif
    AX.register_for_notif( @ref, real_notif, &block )
  end

  # @endgroup

  ##
  # Overriden to produce cleaner output.
  def inspect
    nice_methods = attributes.map { |name| AX.strip_prefix name }
    "\#<#{self.class} @methods=#{nice_methods}>"
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


  protected

  def notif_for sym
    const = "KAX#{sym.to_s.camelize!}Notification"
    Kernel.const_defined?(const) ? Kernel.const_get(const) : nil
  end

  ##
  # Make a string that should match the suffix of a attribute/action
  # constant from an AX::Element object.
  def matcher name
    name = name.to_s
    name.chomp!('?')
    name.delete('_')
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
end
