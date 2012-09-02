# -*- coding: utf-8 -*-

require 'accessibility/core'
require 'accessibility/factory'
require 'accessibility/translator'
require 'accessibility/enumerators'
require 'accessibility/qualifier'
require 'accessibility/errors'
require 'accessibility/pp_inspector'


##
# @abstract
#
# The abstract base class for all accessibility objects. `AX::Element`
# composes low level {AXUIElementRef} objects into a more Rubyish
# interface.
#
# This abstract base class provides generic functionality that all
# accessibility objects require.
class AX::Element
  include Accessibility::PPInspector

  # @param ref [AXUIElementRef]
  def initialize ref
    @ref = ref
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
    @attrs ||= TRANSLATOR.rubyize @ref.attributes
  end

  ##
  # Get the value of an attribute. This method will return `nil` if
  # the attribute does not have a value or if the element is dead. The
  # execption to the rule is that the `:children` attribute will always
  # return an array unless the element does not have the `:children`
  # attribute.
  #
  # @example
  #
  #   element.attribute :position # => #<CGPoint x=123.0 y=456.0>
  #
  # @param attr [#to_sym]
  def attribute attr
    @ref.attribute(TRANSLATOR.cocoaify(attr)).to_ruby
  end

  ##
  # Get the accessibility description for the element.
  #
  # This overrides the inherited `NSObject#description`. If you want a
  # description of the object then you should use {#inspect} instead.
  #
  # @return [String]
  def description
    attribute :description
  end

  ##
  # Fetch the children elements for the current element.
  #
  # @return [Array<AX::Element>]
  def children
    attribute :children
  end

  ##
  # Get a list of elements, starting with the receiver and riding
  # the hierarchy up to the top level object (i.e. the {AX::Application}).
  #
  # @example
  #
  #   element = AX::DOCK.list.application_dock_item
  #   element.ancestry
  #     # => [#<AX::ApplicationDockItem...>, #<AX::List...>, #<AX::Application...>]
  #
  # @return [Array<AX::Element>]
  def ancestry *elements
    elements = [self] if elements.empty?
    element  = elements.last
    if element.attributes.include? :parent
      ancestry(elements << element.parent)
    else
      elements
    end
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
    @ref.pid
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
  # @param attr [#to_sym]
  # @return [Number]
  def size_of attr
    @ref.size_of TRANSLATOR.cocoaify attr
  end

  ##
  # Check whether or not an attribute is writable.
  #
  # @example
  #
  #   element.writable? :size  # => true
  #   element.writable? :value # => false
  #
  # @param attr [#to_sym]
  def writable? attr
    @ref.writable? TRANSLATOR.cocoaify attr
  end

  ##
  # Set a writable attribute on the element to the given value.
  #
  # @example
  #
  #   element.set :value, 'Hello, world!'
  #   element.set :size,  [100, 200].to_size
  #
  # @param attr [#to_sym]
  # @return the value that you were setting is returned
  def set attr, value
    unless writable? attr
      raise ArgumentError, "#{attr} is read-only for #{inspect}"
    end
    value = value.relative_to(@ref.value.size) if value.kind_of? Range
    @ref.set TRANSLATOR.cocoaify(attr), value
  end


  # @group Parameterized Attributes

  ##
  # List of available parameterized attributes. Most elements have no
  # parameterized attributes, but the ones that do have many.
  #
  # @example
  #
  #   window.parameterized_attributes     # => []
  #   text_field.parameterized_attributes # => [:string_for_range, :attributed_string, ...]
  #
  # @return [Array<Symbol>]
  def parameterized_attributes
    @param_attrs ||= TRANSLATOR.rubyize @ref.parameterized_attributes
  end

  ##
  # Get the value for a parameterized attribute.
  #
  # @example
  #
  #  text_field.parameterized_attribute :string_for_range, 2..8
  #
  # @param attr [#to_sym]
  # @param param [Object]
  def parameterized_attribute attr, param
    param = param.relative_to(@ref.value.size) if value.kind_of? Range
    @ref.parameterized_attribute(TRANSLATOR.cocoaify(attr), param).to_ruby
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
  # @return [Array<Symbol>]
  def actions
    @actions ||= TRANSLATOR.rubyize @ref.actions
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
  #   button.perform :press    # => true
  #   button.perform :make_pie # => false
  #
  # @param action [#to_sym]
  # @return [Boolean] true if successful
  def perform action
    @ref.perform TRANSLATOR.cocoaify action
  end


  # @group Search

  ##
  # Perform a breadth first search through the view hierarchy rooted at
  # the current element. If you are concerned about the return value of
  # this method, you can call {#blank?} on the return object.
  #
  # See the [Searching wiki](http://github.com/Marketcircle/AXElements/wiki/Searching)
  # for the details on search semantics.
  #
  # @example Find the dock icon for the Finder app
  #
  #   AX::DOCK.search(:application_dock_item, title:'Finder')
  #
  # @param kind [#to_s]
  # @param filters [Hash{Symbol=>Object}]
  # @yield Optional block used for filtering
  # @return [AX::Element,nil,Array<AX::Element>,Array<>]
  def search kind, filters = {}, &block
    kind      = kind.to_s
    qualifier = Accessibility::Qualifier.new(kind, filters, &block)
    tree      = Accessibility::Enumerators::BreadthFirst.new(self)

    if TRANSLATOR.singularize(kind) == kind
      tree.find     { |element| qualifier.qualifies? element }
    else
      tree.find_all { |element| qualifier.qualifies? element }
    end
  end

  ##
  # Search for an ancestor of the current element.
  #
  # As the opposite of {#search}, this also takes filters, and can
  # be used to find a specific ancestor for the current element.
  #
  # @example
  #
  #   button.ancestor :window       # => #<AX::StandardWindow>
  #   row.ancestor    :scroll_area  # => #<AX::ScrollArea>
  #
  # @param kind [#to_s]
  # @param filters [Hash{Symbol=>Object}]
  # @yield Optional block used for search filtering
  # @return [AX::Element]
  def ancestor kind, filters = {}, &block
    qualifier = Accessibility::Qualifier.new(kind, filters, &block)
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
  # Failing all lookups, this method calls `super`, which will probably
  # raise an exception; however, most elements have children and so it
  # is more likely that you will get an {Accessibility::SearchFailure}
  # in cases where you sholud get a `NoMethodError`.
  #
  # @example
  #
  #   mail   = Accessibility.application_with_bundle_identifier 'com.apple.mail'
  #
  #   # attribute lookup
  #   window = mail.focused_window
  #   # is equivalent to
  #   window = mail.attribute :focused_window
  #
  #   # attribute setting
  #   window.position = CGPoint.new(100, 100)
  #   # is equivalent to
  #   window.set :position, CGPoint.new(100, 100)
  #
  #   # parameterized attribute lookup
  #   window.title_ui_element.string_for_range 1..10
  #   # is equivalent to
  #   title = window.attribute :title_ui_element
  #   title.parameterized_attribute :string_for_range, 1..10
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
  #   # searching from #method_missing will #raise if nothing is found
  #   window.application # => SearchFailure is raised
  #
  def method_missing method, *args, &block
    return set(method.chomp(EQUALS), args.first) if method[-1] == EQUALS

    key = TRANSLATOR.cocoaify method
    if @ref.attributes.include? key
      return attribute(method)

    elsif @ref.parameterized_attributes.include? key
      return paramaterized_attribute(method, args.first)

    elsif @ref.attributes.include? KAXChildrenAttribute
      if (result = search(method, *args, &block)).blank?
        raise Accessibility::SearchFailure.new(self, method, args.first, &block)
      else
        return result
      end

    else
      super

    end
  end

  # @endgroup


  ##
  # Get relevant details about the current object.
  #
  # @return [String]
  def inspect
    msg  = "#<#{self.class}" << pp_identifier
    msg << pp_position if attributes.include? :position
    msg << pp_children if attributes.include? :children
    msg << pp_checkbox(:enabled) if attributes.include? :enabled
    msg << pp_checkbox(:focused) if attributes.include? :focused
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
  # Get the relevant details about the receiver and also the children
  # and further descendents of the receiver. Each generation down the
  # tree will be indented one level further.
  #
  # @example
  #
  #   puts app.inspect_subtree
  #
  # @return [String]
  def inspect_subtree
    output = self.inspect + "\n"
    enum   = Accessibility::Enumerators::DepthFirst.new self
    enum.each_with_level do |element, depth|
      output << "\t"*depth + element.inspect + "\n"
    end
    output
  end

  ##
  # Overriden to respond properly with regards to dynamic attribute
  # lookups, but will return false for potential implicit searches.
  #
  # This does not work for predicate methods at the moment.
  def respond_to? name
    key = TRANSLATOR.cocoaify name.chomp(EQUALS)
    @ref.attributes.include?(key)               ||
    @ref.parameterized_attributes.include?(key) ||
    super
  end

  ##
  # Get the center point of the element.
  #
  # @return [CGPoint]
  def to_point
    size  = attribute :size
    point = attribute :position
    point.x += size.width  / 2
    point.y += size.height / 2
    point
  end
  alias_method :hitpoint, :to_point

  ##
  # Get the bounding rectangle for the element.
  #
  # @return [CGRect]
  def bounds
    CGRect.new(attribute(:position), attribute(:size))
  end
  alias_method :rect, :bounds

  ##
  # Get the application object for the element.
  #
  # @return [AX::Application]
  def application
    @ref.application.to_ruby
  end

  # (see NilClass#blank?)
  def blank?
    false
  end

  ##
  # Return whether or not the receiver is "dead".
  #
  # A dead element is one that is no longer in the app's view
  # hierarchy. This is not directly related to visibility, but an
  # element that is invalid will not be visible, but an invisible
  # element might not be invalid.
  def invalid?
    @ref.invalid?
  end

  ##
  # Like {#respond_to?}, this is overriden to include attribute methods.
  # Though, it does include dynamic predicate methods at the moment.
  def methods include_super = true, include_objc_super = false
    super.concat(attributes).concat(parameterized_attributes)
  end

  ##
  # Overridden so that equality testing would work.
  #
  # A hack, but the only sane way I can think of to test for equivalency.
  def == other
    @ref == other.instance_variable_get(:@ref)
  end
  alias_method :eql?, :==
  alias_method :equal?, :==


  private

  # @private
  # @return [String]
  EQUALS = '='

  # @private
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

end


# Extensions so checking `#blank?` on search result "just works".
class NSArray
  # (see NilClass#blank?)
  alias_method :blank?, :empty?
end

# Extensions so checking `#blank?` on search result "just works".
class NilClass
  ##
  # Whether or not the object is "blank". The concept of blankness
  # borrowed from `Active Support` and is true if the object is falsey
  # or `#empty?`.
  #
  # This method is used by implicit searching in AXElements to
  # determine if searches yielded responses.
  def blank?
    true
  end
end
