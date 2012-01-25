require 'accessibility/core'
require 'accessibility/translator'

##
# Mixin made for processing low level data from AXAPI methods.
module Accessibility::Factory
  include Accessibility::Core

  ##
  # Processes any given data from an AXAPI method and wraps it if
  # needed. Meant for taking a return value from {Accessibility::Core#attr:for:}
  # and friends.
  #
  # Generally, used to process an `AXValue` into a `CGPoint` or an
  # `AXUIElementRef` into some kind of {AX::Element} object.
  def process value
    return nil if value.nil? # CFGetTypeID(nil) crashes runtime
    case CFGetTypeID(value)
    when ARRAY_TYPE then process_array value
    when REF_TYPE   then process_element value
    when BOX_TYPE   then unwrap value
    else
      value
    end
  end

  private

  ##
  # Reference to the singleton instance of the translator.
  #
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

  ##
  # Type ID for `AXUIElementRef` objects.
  #
  # @return [Number]
  REF_TYPE   = AXUIElementGetTypeID()

  ##
  # Type ID for `CFArrayRef` objects.
  #
  # @return [Number]
  ARRAY_TYPE = CFArrayGetTypeID()

  # Type ID for `AXValueRef` objects.
  #
  # @return [Number]
  BOX_TYPE   = AXValueGetTypeID()

  ##
  # @todo Should we handle cases where a subrole has a value of
  #       'Unknown'? What is the performance impact?
  #
  # Takes an `AXUIElementRef` and gives you some kind of wrapped
  # accessibility object.
  #
  # Some code paths have been unrolled for efficiency. Don't hate player,
  # hate the game.
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
  # We assume a homogeneous array and only wrap element arrays right now.
  #
  # @return [Array]
  def process_array vals
    return vals if vals.empty?
    return vals if CFGetTypeID(vals.first) != REF_TYPE
    return vals.map { |val| process_element val }
  end

  ##
  # Find the class for a given role. If the class does not exist it will
  # be created on demand.
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
  # Find the class for a given subrole and role. If the class does not
  # exist it will be created on demand.
  #
  # @param [#to_s]
  # @param [#to_s]
  # @return [Class]
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
  # @param [#to_s] superklass
  # @return [Class]
  def create_class name, with_superclass: superklass
    unless AX.const_defined? superklass, false
      create_class superklass
    end
    klass = Class.new AX.const_get(superklass)
    AX.const_set name, klass
  end

end
