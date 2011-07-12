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
  # @todo Implement method a single loop
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
  # Need to override the provided find method because it does not break
  # properly when something is found, which not only negates the
  # performance boost.
  def find
    pending = [@root]
    until pending.empty?
      pending.shift.attribute(:children).each do |x|
        pending << x if x.respond_to?(:children)
        return x if yield x
      end
    end
  end

end
