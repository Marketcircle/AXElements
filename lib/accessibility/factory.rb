require 'accessibility/core'
require 'accessibility/translator'

##
# Set of methods used for processing low level data from AXAPI methods.
#
# The processing can sometimes require some fancy metaprogramming and should
module Accessibility::Factory
  include Accessibility::Core

  TRANSLATOR = Accessibility::Translator.instance

  ##
  # Retrieve and process the value of the given attribute for the
  # given element reference.
  #
  # @param [AXUIElementRef]
  # @param [String]
  def attribute attr, for: ref
    process attr(attr, for: ref)
  end

  ##
  # Retrieve and process the value of the given parameterized attribute
  # for the parameter and given element reference.
  #
  # @param [AXUIElementRef]
  # @param [String]
  def param_attribute attr, for_param: param, for: ref
    process param_attr(attr, for_param: param.to_axvalue, for: ref)
  end

  ##
  # Processes any given data from an AXAPI method and wraps it if
  # needed. Meant for taking a return value from {Accessibility::Core#attr:for:}
  # and friends.
  #
  # Generally, used to process an `AXValue` into a `CGPoint` or an
  # `AXUIElementRef` into some kind of {AX::Element} object.
  def process value
    return nil if value.nil?
    id = ATTR_MASSAGERS[CFGetTypeID(value)]
    id ? self.send(id, value) : value
  end

  ##
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
  # @todo Should we handle cases where a subrole has a value of
  #       'Unknown'? What is the performance impact?
  #
  # Takes an `AXUIElementRef` and gives you some kind of accessibility
  # object.
  #
  # @param [AXUIElementRef]
  # @return [AX::Element]
  def process_element ref
    attrs = attrs_for ref
    klass = if attrs.include? KAXSubroleAttribute
              subrole, role = role_pair_for ref
              # Some objects claim to have a subrole but return nil
              if subrole
                class_for TRANSLATOR.unprefix(subrole), and: TRANSLATOR.unprefix(role)
              else
                class_for TRANSLATOR.unprefix(role)
              end
            else
              class_for TRANSLATOR.unprefix(role_for ref)
            end
    klass.new ref, attrs
  end

  ##
  # Find the class for a given role.
  #
  # @param [#to_s]
  # @return [Class]
  def class_for role
    if AX.const_defined? role, false
      AX.const_get role
    else
      create_class role
    end
  end

  ##
  # Like `#const_get` except that if the class does not exist yet then
  # it will assume the constant belongs to a class and creates the class
  # for you.
  #
  # @param [Array<String>] const the value you want as a constant
  # @return [Class] a reference to the class being looked up
  def class_for subrole, and: role
    if AX.const_defined? subrole, false
      AX.const_get subrole
    else
      create_class subrole, with_superclass: role
    end
  end

  ##
  # Create a new class in the {AX} namespace that has {AX::Element}
  # as the superclass.
  #
  # @param [#to_s]
  # @return [Class]
  def create_class name
    klass = Class.new AX::Element
    AX.const_set name, klass
  end

  ##
  # Create a new class in the {AX} namesapce that has the given
  # `superklass` as the superclass..
  #
  # @param [#to_s] name
  # @param [String,Symbol] superklass
  # @return [Class]
  def create_class name, with_superclass: superklass
    unless AX.const_defined? superklass, false
      create_class superklass
    end
    klass = Class.new AX.const_get(superklass)
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
  # @todo This should be in {Accessibility::Core} since it works directly
  #       with AXAPI functions.
  #
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
  # Map of type encodings used for wrapping structs when coming from
  # an `AXValueRef`.
  #
  # The list is order sensitive, which is why we unshift nil, but
  # should probably be more rigorously defined at runtime.
  #
  # @return [String,nil]
  BOX_TYPES = [CGPoint, CGSize, CGRect, CFRange].map! { |x| x.type }.unshift(nil)

end
