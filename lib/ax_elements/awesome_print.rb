require 'awesome_print'

module AwesomePrint::AXElements

  def self.included base
    base.send :alias_method, :cast_without_ax_elements, :cast
    base.send :alias_method, :cast, :cast_with_ax_elements
  end

  def cast_with_ax_elements object, type
    cast = cast_without_ax_elements object, type
    cast = :ax_element if object.kind_of? ::AX::Element
    cast
  end


  private

  def awesome_ax_element object
    object.inspect
  end

end

AwesomePrint::Formatter.send :include, AwesomePrint::AXElements
