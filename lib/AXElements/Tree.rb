##
# A UI element tree that can be iterated using lazy evaluation.
#
# This class tries to use as many low level details as possible to get
# better performance out of searches.
class Accessibility::Tree
  include Enumerable

  def initialize root
    @root = root
  end

  ##
  # @todo Make search much faster by not wrapping child classes until
  #       we yield
  #
  # Iterate through the tree in breadth first order.
  def each
    pending = [@root]
    until pending.empty?
      pending.shift.get_attribute(:children).each do |x|
        pending << x if x.respond_to?(:children)
        yield x
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
      pending.shift.get_attribute(:children).each do |x|
        pending << x if x.respond_to?(:children)
        return x if yield x
      end
    end
  end

end
