# Overrides for the Array class that makes it possible to
module ArrayAXElementExtensions

  # If the array contains AX::Element objects, then we can just iterate
  # over the array passing the argument in.
  #
  # You have to be careful in cases where the array contains various
  # types of AX::Element objects that may not have the same attributes
  # or you could end up having a single element throw an exception.
  def method_missing method, *args
    if first.kind_of? AX::Element
      map &method
    else
      super
    end
  end

end

# Monkey patches on top of Array
class Array
  include ArrayAXElementExtensions
end
