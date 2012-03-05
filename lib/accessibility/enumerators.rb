##
# Namespace for enumerators used to navigate accessibility hierarchies.
module Accessibility::Enumerators

  ##
  # Enumerator for visiting each element in a UI hierarchy in breadth
  # first order.
  class BreadthFirst
    include Enumerable

    # @param [AX::Element]
    def initialize root
      @root = root
    end

    ##
    # Semi-lazily iterate through the tree.
    #
    # @yieldparam [AX::Element]
    def each
      # @todo Lazy-wrap element refs, might make things a bit faster
      #       for fat trees; what is impact on thin trees?
      # @todo See if we can implement the method in a single loop
      queue = [@root]
      until queue.empty?
        queue.shift.attribute(:children).each do |x|
          queue << x if x.attributes.include? :children
          yield x
        end
      end
    end

    ##
    # @note Explicitly defined so that escaping at the first found element
    #       actually works. Since only a single `break` is called when an
    #       item is found it does not fully escape the method. Technically,
    #       we need to do this with other 'escape-early' iteraters, but
    #       they aren't being used...yet.
    #
    # Override `Enumerable#find` for performance reasons.
    def find
      each { |x| return x if yield x }
    end

  end

  ##
  # Enumerator for visitng each element in a UI hierarchy in
  # depth first order.
  class DepthFirst
    include Enumerable

    # @param [AX::Element]
    def initialize root
      @root = root
    end

    # @yieldparam [AX::Element]
    def each
      stack = @root.attribute(:children)
      until stack.empty?
        current = stack.shift
        yield current
        if current.attributes.include? :children
          # need to reverse it since child ordering seems to matter in practice
          stack.unshift *current.attribute(:children)
        end
      end
    end

    ##
    # Walk the UI element tree and yield both the element and the level
    # that the element is at relative to the root.
    #
    # @yieldparam [AX::Element]
    # @yieldparam [Number]
    def each_with_level &block
      # @todo A bit of a hack that I would like to fix one day...
      @root.attribute(:children).each do |element|
        recursive_each_with_level element, 1, block
      end
    end


    private

    ##
    # Recursive implementation of a depth first iterator.
    #
    # @param [AX::Element]
    # @param [Number]
    # @param [#call]
    def recursive_each_with_level element, depth, block
      block.call element, depth
      if element.respond_to? :children
        element.attribute(:children).each do |x|
          recursive_each_with_level x, depth + 1, block
        end
      end
    end

  end

end
