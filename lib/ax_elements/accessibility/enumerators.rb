##
# @abstract
#
# Common code for all enumerators.
class Accessibility::AbstractEnumerator
  include Enumerable

  ##
  # Caches the root.
  #
  # @param [AX::Element] root
  def initialize root
    @root = root
  end

end

##
# Enumerator for visiting each element in a UI hierarchy in breadth
# first order.
class Accessibility::BFEnumerator < Accessibility::AbstractEnumerator

  ##
  # @todo Lazy-wrap element refs, might make things a bit faster
  #       for fat trees; what is impact on thin trees?
  # @todo See if we can implement method in a single loop
  #
  # Lazily iterate through the tree.
  #
  # @yieldparam [AX::Element] element a descendant of the root element
  def each
    queue = [@root]
    until queue.empty?
      queue.shift.attribute(:children).each do |x|
        queue << x if x.attributes.include? KAXChildrenAttribute
        yield x
      end
    end
  end

  ##
  # Explicitly defined so that escaping at the first found element
  # actually works. Since only a single `break` is called when an item
  # is found it does not fully escape the method.
  #
  # Technically, we need to do this with other 'escape-early' iteraters,
  # but they aren't being used...
  def find
    each { |x| return x if yield x }
  end

end

##
# Enumerator for visitng each element in a UI hierarchy in
# depth first order.
class Accessibility::DFEnumerator < Accessibility::AbstractEnumerator

  # @yieldparam [AX::Element] elemnet a descendant of the root
  def each
    stack = @root.attribute(:children)
    until stack.empty?
      current = stack.shift
      yield current
      if current.attributes.include? KAXChildrenAttribute
        # need to reverse it since child ordering seems to matter in practice
        stack.unshift *current.attribute(:children)
      end
    end
  end

  ##
  # @todo A bit of a hack that I would like to fix one day...
  #
  # Walk the UI element tree and yield both the element and the depth
  # in three relative to the root.
  #
  # @yieldparam [AX::Element] element
  # @yieldparam [Number] depth
  def each_with_height &block
    @root.attribute(:children).each do |element|
      recursive_each_with_height element, 1, block
    end
  end


  private

  ##
  # Recursive implementation of a depth first iterator.
  #
  # @param [AX::Element]
  # @param [Number]
  # @param [#call]
  def recursive_each_with_height element, depth, block
    block.call element, depth
    if element.attributes.include? KAXChildrenAttribute
      element.attribute(:children).each do |x|
        recursive_each_with_height x, depth + 1, block
      end
    end
  end

end
