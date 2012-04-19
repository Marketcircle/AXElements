require 'accessibility/qualifier'
require 'ax/element'

##
# Custom matcher for RSpec to check if an element has the specified
# child element.
class Accessibility::HasChildMatcher

  # @param [#to_s]
  # @param [Hash]
  # @yield
  def initialize kind, filters, &block
    @qualifier = Accessibility::Qualifier.new(kind, filters, &block)
  end

  # @param [AX::Element]
  def matches? parent
    @parent = parent
    @result = parent.children.find { |x| @qualifier.qualifies? x }
    !@result.blank?
  end

  # @return [String]
  def failure_message_for_should
    "Expected #@parent to have child #{@qualifier.describe}"
  end

  # @param [AX::Element]
  def does_not_match? parent
    !matches?(parent)
  end

  # @return [String]
  def failure_message_for_should_not
    "Expected #@parent to NOT have child #@result"
  end

  # @return [String]
  def description
    "should have a child that matches #{@qualifier.describe}"
  end

end

##
# Assert that the receiving element has the specified child element. You
# can use any filters you would normally use in a search, including
# a block.
#
# @example
#
#   window.toolbar.should have_child(:search_field)
#   table.should have_child(:row, static_text: { value: /42/ })
#
#   search_field.should_not have_child(:busy_indicator)
#
# @param [#to_s]
# @param [Hash]
# @yield An optional block to be used as part of the search qualifier
def have_child kind, filters = {}, &block
  Accessibility::HasChildMatcher.new kind, filters, &block
end


##
# Custom matcher for RSpec to check if an element has the specified
# descendent element.
class Accessibility::HasDescendentMatcher

  # @param [#to_s]
  # @param [Hash]
  # @yield
  def initialize kind, filters, &block
    @kind, @filters, @block = kind, filters, block
    @qualifier = Accessibility::Qualifier.new(@kind, @filters, &@block)
  end

  # @param [AX::Element]
  def matches? ancestor
    @ancestor = ancestor
    @result   = ancestor.search(@kind, @filters, &@block)
    !@result.blank?
  end

  # @return [String]
  def failure_message_for_should
    "Expected #@ancestor to have descendent #{@qualifier.describe}"
  end

  # @param [AX::Element]
  def does_not_match? ancestor
    !matches?(ancestor)
  end

  # @return [String]
  def failure_message_for_should_not
    "Expected #@ancestor to NOT have descendent #@result"
  end

  # @return [String]
  def description
    "should have a descendent matching #{@qualifier.describe}"
  end

end

##
# Assert that the given element has the specified descendent. You can
# pass any parameters you normally would use during a search,
# including a block.
#
# @example
#
#   app.main_window.should have_descendent(:button, title: 'Press Me')
#
#   row.should_not have_descendent(:check_box)
#
# @param [#to_s]
# @param [Hash]
# @yield An optional block to be used as part of the search qualifier
def have_descendent kind, filters = {}, &block
  Accessibility::HasDescendentMatcher.new kind, filters, &block
end
alias :have_descendant :have_descendent
