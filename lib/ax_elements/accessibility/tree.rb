##
# A lazy tree structure for a UI hierarchy.
#
# Currently the only form of enumeration is breadth first, but this can
# be properly fleshed out as needed in the future.
class Accessibility::Tree
  include Enumerable

  ##
  # Caches the root.
  #
  # @param [AX::Element]
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
  # Dump a tree to the console, indenting for each level down the
  # tree that we go, and inspecting each element.
  #
  # @return [nil] do not count on a return
  def dump
    depth_first_dump @root, 0
    nil
  end

  ##
  # Make a `dot` format graph of the tree, meant for graphing with
  # GraphViz.
  #
  # @return [String]
  def to_dot
    raise NotImplementedError, 'Please implement me, :('
  end


  private

  ##
  # Walk the UI element tree in a depth first order, and inspect
  # each element along the way.
  #
  # @param [AX::Element] element
  def depth_first_dump element, depth
    puts "\t"*depth + element.inspect
    if element.respond_to? :children
      element.attribute(:children).each do |x|
        depth_first x, depth + 1
      end
    end
  end

end
