##
# A lazy tree structure for a UI hierarchy.
#
# Currently the only form of enumeration is breadth first, but this can
# be properly fleshed out as needed in the future.
class Accessibility::Tree
  include Enumerable

  ##
  # Caches the root
  def initialize root
    @root = root
  end

  ##
  # @todo Lazy-wrap element refs, should make things a bit faster
  # @todo Implement method in a single loop
  #
  # Iterate through the tree in breadth first order.
  def each
    pending = [@root]
    until pending.empty?
      current = pending
      pending = []
      current.each do |element|
        element.attribute(:children).each do |x|
          pending << x if x.respond_to? :children
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
  # @todo Lazy-wrap element refs, should make things a bit faster
  # @todo Implement method in a single loop
  #
  # Iterate through the tree in breadth first order which keeping track
  # of the current height of the tree.
  def each_with_height
    pending = [@root]
    height = 0
    until pending.empty?
      current = pending
      pending = []
      height += 1
      current.each do |element|
        element.attribute(:children).each do |x|
          pending << x if x.respond_to? :children
          yield x, height
        end
      end
    end
  end

  ##
  # Make a `dot` format graph of the tree, meant for graphing with
  # GraphViz.
  #
  # @return [String]
  def to_dot
    each_with_height do |element, height|
      puts height
    end
  end

end
