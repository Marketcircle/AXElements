require 'accessibility/dsl'
require 'accessibility/qualifier'
require 'ax/element'

module Accessibility

  ##
  # @abstract
  #
  # Base class for RSpec matchers used with AXElements.
  class AbstractMatcher

    # @return [#to_s]
    attr_reader :kind

    # @return [Hash{Symbol=>Object}]
    attr_reader :filters

    # @return [Proc]
    attr_reader :block

    # @param kind [#to_s]
    # @param filters [Hash]
    # @yield Optional block used for search filtering
    def initialize kind, filters, &block
      @kind, @filters, @block = kind, filters, block
    end

    # @param element [AX::Element]
    def does_not_match? element
      !matches?(element)
    end


    private

    # @return [Accessibility::Qualifier]
    def qualifier
      @qualifier ||= Accessibility::Qualifier.new(kind, filters, &block)
    end
  end

  ##
  # Custom matcher for RSpec to check if an element has the specified
  # child element.
  class HasChildMatcher < AbstractMatcher
    # @param parent [AX::Element]
    def matches? parent
      @parent = parent
      @result = parent.children.find { |x| qualifier.qualifies? x }
      !@result.blank?
    end

    # @return [String]
    def failure_message_for_should
      "Expected #@parent to have child #{qualifier.describe}"
    end

    # @return [String]
    def failure_message_for_should_not
      "Expected #@parent to NOT have child #@result"
    end

    # @return [String]
    def description
    "should have a child that matches #{qualifier.describe}"
    end
  end

  ##
  # Custom matcher for RSpec to check if an element has the specified
  # descendent element.
  class HasDescendentMatcher < AbstractMatcher
    # @param ancestor [AX::Element]
    def matches? ancestor
      @ancestor = ancestor
      @result   = ancestor.search(kind, filters, &block)
      !@result.blank?
    end

    # @return [String]
    def failure_message_for_should
      "Expected #@ancestor to have descendent #{qualifier.describe}"
    end

    # @return [String]
    def failure_message_for_should_not
      "Expected #@ancestor to NOT have descendent #@result"
    end

    # @return [String]
    def description
      "should have a descendent matching #{qualifier.describe}"
    end
  end

  ##
  # Custom matcher for RSpec to check if an element has the specified
  # child element within a grace period. Used for testing things
  # after an asynchronous action is performed.
  class HasChildShortlyMatcher < AbstractMatcher
    include DSL

    # @param parent [AX::Element]
    def matches? parent
      @filters[:parent] = @parent = parent
      @result = wait_for kind, filters, &block
      !@result.blank?
    end

    # @return [String]
    def failure_message_for_should
      "Expected #@parent to have child #{qualifier.describe} before a timeout occurred"
    end

    # @return [String]
    def failure_message_for_should_not
      "Expected #@parent to NOT have child #@result before a timeout occurred"
    end

    # @return [String]
    def description
      "should have a child that matches #{qualifier.describe} before a timeout occurs"
    end
  end

  ##
  # Custom matcher for RSpec to check if an element has the specified
  # descendent element within a grace period. Used for testing things
  # after an asynchronous action is performed.
  class HasDescendentShortlyMatcher < AbstractMatcher
    include DSL

    # @param ancestor [AX::Element]
    def matches? ancestor
      @filters[:ancestor] = @ancestor = ancestor
      @result = wait_for kind, filters, &block
      !@result.blank?
    end

    # @return [String]
    def failure_message_for_should
      "Expected #@ancestor to have descendent #{qualifier.describe} before a timeout occurred"
    end

    # @return [String]
    def failure_message_for_should_not
      "Expected #@ancestor to NOT have descendent #@result before a timeout occurred"
    end

    # @return [String]
    def description
      "should have a descendent matching #{qualifier.describe} before a timeout occurs"
    end
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
# @param kind [#to_s]
# @param filters [Hash]
# @yield An optional block to be used as part of the search qualifier
def have_child kind, filters = {}, &block
  Accessibility::HasChildMatcher.new kind, filters, &block
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
# @param kind [#to_s]
# @param filters [Hash]
# @yield An optional block to be used as part of the search qualifier
def have_descendent kind, filters = {}, &block
  Accessibility::HasDescendentMatcher.new kind, filters, &block
end
alias :have_descendant :have_descendent

##
# Assert that the given element has the specified child soon. This
# method will block until the child is found or a timeout occurs. You
# can pass any parameters you normally would use during a search,
# including a block.
#
# @example
#
#   app.main_window.should shortly_have_child(:row, static_text: { value: 'Cake' })
#
#   row.should_not shortly_have_child(:check_box)
#
# @param kind [#to_s]
# @param filters [Hash]
# @yield An optional block to be used as part of the search qualifier
def shortly_have_child kind, filters = {}, &block
  Accessibility::HasChildShortlyMatcher.new(kind, filters, &block)
end

##
# Assert that the given element has the specified descendent soon. This
# method will block until the descendent is found or a timeout occurs.
# You can pass any parameters you normally would use during a search,
# including a block.
#
# @example
#
#   app.main_window.should shortly_have_child(:row, static_text: { value: 'Cake' })
#
#   row.should_not shortly_have_child(:check_box)
#
# @param kind [#to_s]
# @param filters [Hash]
# @yield An optional block to be used as part of the search qualifier
def shortly_have_descendent kind, filters = {}, &block
  Accessibility::HasDescendentShortlyMatcher.new kind, filters, &block
end
alias :shortly_have_descendant :shortly_have_descendent
