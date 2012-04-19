require 'awesome_print'

##
# `AwesomePrint` extension for AXElements.
module AwesomePrint::AXElements

  ##
  # Perform the silly `alias_method_chain` stuff that AwesomePrint
  # expects.
  def self.included base
    base.send :alias_method, :cast_without_ax_elements, :cast
    base.send :alias_method, :cast, :cast_with_ax_elements
  end

  ##
  # Format {AX::Element} objects for AwesomePrint. For the time
  # being, just work-around the default AwesomePrint output by
  # using the default `#inpspect` for {AX::Element}.
  def cast_with_ax_elements object, type
    cast = cast_without_ax_elements object, type
    cast = :ax_element if object.kind_of? ::AX::Element
    cast
  end


  private

  ##
  # Give the awesome output for an {AX::Element} object.
  #
  # @return [String]
  def awesome_ax_element object
    object.inspect
  end

end

AwesomePrint::Formatter.send :include, AwesomePrint::AXElements
