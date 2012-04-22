require 'accessibility/core'
require 'accessibility/translator'

##
# Namespace container for all the accessibility objects.
module AX; end

##
# Mixin made for processing low level data from AXAPI methods.
module Accessibility::Factory

  # @todo This should provide alternate #to_ruby functionality for
  #       the __NSCFType class in order to avoid the overhead of
  #       checking type information (or at least reducing it).
  #       However, it will force the lower level to always wrap
  #       element references; this should be ok most of the time
  #       but makes testing a bit of a pain...hmmm

  ##
  # Processes any given data from an AXAPI function and wraps it if
  # needed. Meant for taking a return value from
  # {Accessibility::Core#attribute} and friends.
  #
  # Generally, used to process an `AXUIElementRef` into a some kind
  # of {AX::Element} subclass.
  def process value
    return nil if value.nil? # CFGetTypeID(nil) crashes runtime
    case CFGetTypeID(value)
    when ARRAY_TYPE then process_array value
    when REF_TYPE   then process_element value
    else
      value
    end
  end


  private

  ##
  # @private
  #
  # Reference to the singleton instance of the translator.
  #
  # @return [Accessibility::Translator]
  TRANSLATOR = Accessibility::Translator.instance

  ##
  # @private
  #
  # Type ID for `AXUIElementRef` objects.
  #
  # @return [Number]
  REF_TYPE   = AXUIElementGetTypeID()

  ##
  # @private
  #
  # Type ID for `CFArrayRef` objects.
  #
  # @return [Number]
  ARRAY_TYPE = CFArrayGetTypeID()

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
    if role = ref.role
      role  = TRANSLATOR.unprefix role
      attrs = ref.attributes
      if attrs.include? KAXSubroleAttribute
        subrole = ref.subrole
        # Some objects claim to have a subrole but return nil
        if subrole
          class_for2(TRANSLATOR.unprefix(subrole), role).new ref
        else
          class_for(role).new ref
        end
      else
        class_for(role).new ref
      end
    else # failsafe in case object dies before we even get the role
      AX::Element.new ref
    end
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
  # @todo Consider using {AX.const_missing} instead.
  #
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
  def class_for2 subrole, role
    # @todo it would be nice if we didn't have to lookup twice
    if AX.const_defined? subrole, false
      AX.const_get subrole
    else
      create_class2 subrole, role
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
  def create_class2 name, superklass
    unless AX.const_defined? superklass, false
      create_class superklass
    end
    klass = Class.new AX.const_get(superklass)
    AX.const_set name, klass
  end

end
