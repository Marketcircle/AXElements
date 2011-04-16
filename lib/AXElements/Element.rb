module AX

##
# @abstract
#
# The abstract base class for all accessibility objects.
class Element

  # @param [AXUIElementRef] element
  def initialize element
    @ref        = element
    @attributes = AX.attrs_of_element(element)
  end

  # @return [Array<String>] cache of available attributes
  attr_reader :attributes

  # @return [Array<String>] cache of available actions
  def actions; @actions ||= AX.actions_of_element(@ref); end

  # @return [Array<String>] cache of available actions
  def param_attributes; @param_attributes ||= AX.param_attrs_of_element(@ref); end

  # @return [Fixnum]
  def pid
    @pid ||= AX.pid_of_element( @ref )
  end

  # @param [Symbol] attr
  def get_attribute attr
    real_attribute = attribute_for attr
    raise ArgumentError, "#{attr} is not an attribute" unless real_attribute
    attribute(real_attribute)
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
  # @todo Consider a default value for attr to be KAXValueAttribute
  #
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
  # Needed to override inherited {NSObject#description}. If you want a
  # description of the object try using {#inspect}.
  def description
    self.method_missing :description
  end

  ##
  # @todo allow regex matching when filtering string attributes
  # @todo decide whether plural or singular search before entering
  #       the main loop
  # @todo make search much faster by not wrapping child classes
  # @todo refactor searching, perhaps make an iterator
  # @todo consider using the rails inflector for pluralization checking
  #
  # Perform a breadth first search through the view hierarchy rooted at
  # the current element.
  #
  # See the documentation page [Searching](file/Searching.markdown)
  # on the details of how to search.
  #
  # @example Find the dock item for the Finder app
  #  AX::DOCK.search( :application_dock_item, title: 'Finder' )
  #
  # @param [Symbol,String] element_type
  # @param [Hash{Symbol=>Object}] filters
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search element_type, filters = {}
    element_type   = element_type.to_s
    class_const    = element_type.camelize!.chomp('s')
    elements       = attribute(KAXChildrenAttribute)
    search_results = []
    filters      ||= {}

    until elements.empty?
      element          = elements.shift
      primary_filter ||= (AX.const_get(class_const) if AX.const_defined?(class_const))

      if element.attributes.include?(KAXChildrenAttribute)
        elements.concat element.send(:attribute, KAXChildrenAttribute)
      end

      next unless element.class == primary_filter
      next if filters.find { |filter,value| element.send(filter) != value }

      return element unless element_type[-1] == 's'
      search_results << element
    end

    element_type[-1] == 's' ? search_results : nil
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
    return AX.attr_of_element(@ref, attr) if attr
    return search(method, args.first) if attributes.include?(KAXChildrenAttribute)
    super
  end

  ##
  # @todo Need to provide a nice interface for taking notif names
  #       (i.e. `:window_created` instead of `KAXWindowCreatedNotification`)
  #
  # Optimized under the assumption that you will be passing a block much
  # less frequently than not.
  #
  # @yield
  # @yieldreturn [Boolean]
  # @param [String] notif
  # @param [Float] timeout
  def wait_for_notification notif, timeout = 10
    AX.wait_for_notification( @ref, notif, timeout )
  end

  ##
  # Overriden to produce cleaner output.
  def inspect
    nice_methods = attributes.map { |name| AX.strip_prefix name }
    "\#<#{self.class} @methods=#{nice_methods}>"
  end

  ##
  # @todo FINISH THIS METHOD
  #
  # A more expensive {#inspect} where we actually look up the
  # values for each attribute and format the output nicely.
  def pretty_print
    inspect
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

  ##
  # A short path when you have the exact name of the attribute you want
  # to retrieve the value of.
  #
  # This API exists for the sake of making search much faster.
  def attribute name; AX.attr_of_element( @ref, name ); end
  # This API exists to be consistent with {#attribute}.
  def action name; AX.perform_action_of_element( @ref, name ); end
  # This API exists to be consistent with {#attribute}.
  def param_attribute name, param; AX.param_attr_of_element( @ref, name, param ); end
  # This API exists to be consistent with {#attribute}.
  def attribute= name, value; AX.set_attr_of_element( @ref, name, value ); end

  ##
  # Make a string that should match the suffix of a attribute/action
  # constant from an AX::Element object.
  def matcher name
    name = name.to_s
    name = "Is#{name}" if name.chomp!('?')
    name.delete('_')
  end

  def attribute_for sym;       constant_for sym, attributes;       end
  def action_for sym;          constant_for sym, actions;          end
  def param_attribute_for sym; constant_for sym, param_attributes; end

  ##
  # Match a symbol to a attribute/action constant a suffix of an action
  # constant.
  #
  # @return [String,nil]
  def constant_for sym, array
    suffix = matcher(sym)
    array.find { |const|
      AX.strip_prefix(const).caseInsensitiveCompare(suffix) == NSOrderedSame
    }
  end

end
end
