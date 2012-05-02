require 'ax/element'
require 'accessibility/qualifier'
require 'accessibility/dsl'

##
# AXElements assertions for MiniTest.
# [Learn more about minitest.](https://github.com/seattlerb/minitest)
class MiniTest::Assertions

  ##
  # Test that an element has a specific child. For example, test
  # that a table has a row with certain contents. You can pass any
  # filters that you normally would during a search, including a block.
  #
  # @example
  #
  #   assert_has_child table, :row, static_text: { value: 'Mark' }
  #
  # @param parent [AX::Element]
  # @param kind [#to_s]
  # @param filters [Hash]
  # @yield Optional block used for filtering
  # @return [AX::Element]
  def assert_has_child parent, kind, filters = {}, &block
    msg = message {
      child = ax_search_id kind, filters, block
      "Expected #{parent.inspect} to have #{child} as a child"
    }
    result = ax_check_children parent, kind, filters, block
    refute result.blank?, msg
    result
  end

  ##
  # Test that an element has a specifc descendent. For example, test
  # that a window contains a specific label. You can pass any filters
  # that you normally would during a search, including a block.
  #
  # @example
  #
  #   assert_has_descendent window, :static_text, value: /Cake/
  #
  # @param ancestor [AX::Element]
  # @param kind [#to_s]
  # @param filters [Hash]
  # @yield Optional block used for filtering
  # @return [AX::Element]
  def assert_has_descendent ancestor, kind, filters = {}, &block
    msg = message {
      descendent = ax_search_id kind, filters, block
      "Expected #{ancestor.inspect} to have #{descendent} as a descendent"
    }
    result = ax_check_descendent ancestor, kind, filters, block
    refute result.blank?, msg
    result
  end
  alias_method :assert_has_descendant, :assert_has_descendent

  ##
  # Test that an element will have a child/descendent soon. This method
  # will block until the element is found or a timeout occurs.
  #
  # This is a minitest front end to using {DSL#wait_for}, so any
  # parameters you would normally pass to that method will work here.
  # This also means that you must include either a `parent` key or an
  # `ancestor` key as one of the filters.
  #
  # @param kind [#to_s]
  # @param filters [Hash]
  # @yield An optional block to be used in the search qualifier
  def assert_shortly_has kind, filters = {}, &block
    # need to know if parent/ancestor now because wait_for eats some keys
    (ancest = filters[:ancestor]) || (parent = filters[:parent])
    msg = message {
      descend = ax_search_id kind, filters, block
      if ancest
        "Expected #{ancest.inspect} to have descendent #{descend} before a timeout occurred"
      else
        "Expected #{parent.inspect} to have child #{descend} before a timeout occurred"
      end
    }
    result = wait_for kind, filters, &block
    refute result.blank?, msg
    result
  end

  ##
  # Test that an element _does not_ have a specific child. For example,
  # test that a row is no longer in a table. You can pass any filters
  # that you normally would during a search, including a block.
  #
  # @example
  #
  #   refute_has_child table, :row, id: 'MyRow'
  #
  # @param parent [AX::Element]
  # @param kind [#to_s]
  # @param filters [Hash]
  # @yield An optional block to be used in the search qualifier
  # @return [nil]
  def refute_has_child parent, kind, filters = {}, &block
    result = ax_check_children parent, kind, filters, block
    msg    = message {
      "Expected #{parent.inspect} NOT to have #{result} as a child"
    }
    assert result.blank?, msg
    result
  end

  ##
  # Test that an element _does not_ have a specific descendent. For
  # example, test that a window does not contain a spinning progress
  # indicator anymore.
  #
  # @example
  #
  #  refute_has_descendent window, :busy_indicator
  #
  # @param ancestor [AX::Element]
  # @param kind [#to_s]
  # @param filters [Hash]
  # @yield An optional block to be used in the search qualifier
  # @return [nil,Array()]
  def refute_has_descendent ancestor, kind, filters = {}, &block
    result = ax_check_descendent ancestor, kind, filters, block
    msg    = message {
      "Expected #{ancestor.inspect} NOT to have #{result} as a descendent"
    }
    assert result.blank?, msg
    result
  end
  alias_method :refute_has_descendant, :refute_has_descendent

  ##
  # @todo Does having this assertion make sense? I've only added it
  #       for the time being because OCD demands it.
  #
  # Test that an element will NOT have a child/descendent soon. This
  # method will block until the element is found or a timeout occurs.
  #
  # This is a minitest front end to using {DSL#wait_for}, so any
  # parameters you would normally pass to that method will work here.
  # This also means that you must include either a `parent` key or an
  # `ancestor` key as one of the filters.
  #
  # @param kind [#to_s]
  # @param filters [Hash]
  # @yield An optional block to be used in the search qualifier
  # @return [nil]
  def refute_shortly_has kind, filters = {}, &block
    result = wait_for kind, filters, &block
    msg = message {
      if ancest = filters[:ancestor]
        "Expected #{ancest.inspect} NOT to have #{result.inspect} as a descendent"
      else
        parent = filters[:parent]
        "Expected #{parent.inspect} NOT to have #{result.inspect} as a child"
      end
    }
    assert result.blank?, msg
    result
  end


  private

  def ax_search_id kind, filters, block
    Accessibility::Qualifier.new(kind, filters, &block).describe
  end

  def ax_check_children parent, kind, filters, block
    q = Accessibility::Qualifier.new(kind, filters, &block)
    parent.children.find { |x| q.qualifies? x }
  end

  def ax_check_descendent ancestor, kind, filters, block
    ancestor.search(kind, filters, &block)
  end

end
