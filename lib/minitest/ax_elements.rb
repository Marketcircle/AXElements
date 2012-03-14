require 'ax_elements/macruby_extensions'

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
  # @param [AX::Element]
  # @param [#to_s]
  # @param [Hash]
  # @return [AX::Element]
  def assert_has_child parent, kind, filters = {}, &block
    msg = message {
      child = ax_search_id kind, filters, block
      "Expected #{parent.inspect} to have #{child} as a child"
    }
    result = ax_check_children parent, kind, filters, &block
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
  # @param [AX::Element]
  # @param [#to_s]
  # @param [Hash]
  # @return [AX::Element]
  def assert_has_descendent ancestor, kind, filters = {}, &block
    msg = message {
      descendent = ax_search_id kind, filters, block
      "Expected #{ancestor.inspect} to have #{descendent} as a descendent"
    }
    result = ax_check_descendent ancestor, kind, filters, &block
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
  # @param [AX::Element]
  # @param [#to_s]
  # @param [Hash]
  # @return [nil]
  def refute_has_child parent, kind, filters = {}, &block
    msg = message {
      child = ax_search_id kind, filters, block
      "Expected #{parent.inspect} not to have #{child} as a child"
    }
    result = ax_check_children parent, kind, filters, &block
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
  # @param [AX::Element]
  # @param [#to_s]
  # @param [Hash]
  # @return [nil,Array()]
  def refute_has_descendent ancestor, kind, filters = {}, &block
    msg = message {
      descendent = ax_search_id kind, filters, block
      "Expected #{ancestor.inspect} not to have #{descendent} as a descendent"
    }
    result = ax_check_descendent ancestor, kind, filters, &block
    assert result.blank?, msg
    result
  end


  private

  def ax_search_id kind, filters, block
    Accessibility::Qualifier.new(kind, filters, &block).inspect
  end

  def ax_check_children parent, kind, filters, &block
    q = Accessibility::Qualifier.new(kind.classify, filters, &block)
    parent.attribute(:children).find { |x| q.qualifies? x }
  end

  def ax_check_descendent ancestor, kind, filters, &block
    ancestor.search(kind, filters, &block)
  end

end

# @todo assertions for minitest/spec
