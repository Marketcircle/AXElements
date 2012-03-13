require 'ax_elements/macruby_extensions'

class MiniTest::Assertions

  def assert_has_child parent, kind, filters = {}, &block
    msg = proc {
      child = ax_search_id kind, filters
      "Expected #{parent.inspect} to have #{child} as a child"
    }
    refute ax_check_children(parent,children,filters,&block).blank?, msg
  end

  def assert_has_descendent ancestor, kind, filters = {}, &block
    msg = proc {
      descendent = ax_search_id kind, filters
      "Expected #{ancestor.inspect} to have #{descendent} as a descendent"
    }
    refute check_descendent(ancestor,kind,filters,&block).blank?, msg
  end

  def refute_has_child parent, kind, filters = {}, &block
    msg = proc {
      child    = ax_search_id kind, filters
      "Expected #{parent.inspect} not to have #{child} as a child"
    }
    assert ax_check_children(parent,kind,filters,&block).blank?, msg
  end

  def refute_has_descendent ancestor, kind, filters = {}, &block
    msg = proc {
      descendent = ax_search_id kind, filters
      "Expected #{ancestor.inspect} not to have #{descendent} as a descendent"
    }
    assert ax_check_descendent(ancestor,kind,filters,&block).blank?, msg
  end


  private

  def ax_search_id kind, filters
    filter = filters.empty? ? ::EMPTY_STRING : "(#{filters.inspect})"
    "#{kind}#{filter}"
  end

  def ax_check_children parent, kind, filters, &block
    q = Accessibility::Qualifier.new(kind, filters, &block)
    parent.attribute(:children).find { |x| q.qualifies? x }
  end

  def ax_check_descendent ancestor, kind, filters, &block
    ancestor.search(kind, filters, &block)
  end

end

# @todo assertions for minitest/spec
