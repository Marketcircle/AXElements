require 'accessibility/core'
require 'accessibility/translator'

##
# Namespace container for all the accessibility objects.
module AX; class Element; end end


##
# Extensions to {Accessibility::Element} for the high level abstraction.
# These extensions only make sense in the context of the high level API
# and it requires knowledge of both layers, so the code has been placed
# in its own file.
module Accessibility::Element

  ##
  # @todo Should we handle cases where a subrole has a value of
  #       'Unknown'? What is the performance impact?
  #
  # Wrap the low level wrapper with the appropriate high level wrapper.
  # This involves determining the proper class in the {AX} namespace,
  # possibly creating it on demand, and then instantiating the class to
  # wrap the low level object.
  #
  # Some code paths have been unrolled for efficiency. Don't hate player,
  # hate the game.
  #
  # @return [AX::Element]
  def to_ruby
    if roll = self.role
      roll = TRANSLATOR.unprefix roll
      if attributes.include? KAXSubroleAttribute
        subroll = self.subrole
        # Some objects claim to have a subrole but return nil
        if subroll
          class_for2(TRANSLATOR.unprefix(subroll), roll).new self
        else
          class_for(roll).new self
        end
      else
        class_for(roll).new self
      end
    else # failsafe in case object dies before we get the role
      AX::Element.new self
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
  # Serial queue to make sure we only create one class at a time.
  #
  # @return [Dispatch::Queue]
  CREATE_QUEUE = Dispatch::Queue.new 'com.marketcircle.axelements.create'

  ##
  # Find the class for a given role. If the class does not exist it will
  # be created.
  #
  # @param role [#to_s]
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
  # @param subrole [#to_s]
  # @param role [#to_s]
  # @return [Class]
  def class_for2 subrole, role
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
  # @param name [#to_s]
  # @return [Class]
  def create_class name
    CREATE_QUEUE.sync do
      # re-check now that we are in the critical section
      @klass = if AX.const_defined? name, false
                 AX.const_get name
               else
                 klass = Class.new AX::Element
                 AX.const_set name, klass
               end
    end
    @klass
  end

  ##
  # Create a new class in the {AX} namesapce that has the given
  # `superklass` as the superclass..
  #
  # @param name [#to_s]
  # @param superklass [#to_s]
  # @return [Class]
  def create_class2 name, superklass
    unless AX.const_defined? superklass, false
      create_class superklass
    end
    CREATE_QUEUE.sync do
      # re-check now that we are in the critical section
      @klass = if AX.const_defined? name, false
                 AX.const_get name
               else
                 klass = Class.new AX.const_get(superklass)
                 AX.const_set name, klass
               end
    end
    @klass
  end

end
