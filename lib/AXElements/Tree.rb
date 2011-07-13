##
# A lazy tree structure for a UI hierarchy.
#
# Currently the only form of enumeration is breadth first, but this can
# be properly fleshed out as needed in the future.
class Accessibility::Tree
  include Enumerable

  def initialize root
    @root = root
  end

  ##
  # Caches the root
  def initialize current
    @start  = current
    @height = 0
  end

  ##
  # @todo Lazy-wrap element refs, should make things a bit faster
  # @todo Implement method in a single loop
  #
  # Iterate through the tree in breadth first order.
  def each
    pending = [@start]
    until pending.empty?
      current = pending
      pending = []
      @height += 1
      current.each do |element|
        element.attribute(:children).each do |x|
          pending << x if x.respond_to?(:children)
          yield x
        end
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

  ##
  # Make a `dot` format GraphViz graph of the tree.
  #
  # @return [String]
  def to_dot
    each do |x|
      puts @height
    end
  end

end
