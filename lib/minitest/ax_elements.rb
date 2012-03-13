require 'ax_elements/macruby_extensions'

class MiniTest::Assertions

  def assert_has_child parent, kind, filters = {}
    msg = proc {
      child = ax_search_id kind, filters
      "Expected #{parent.inspect} to have #{child} as a child"
    }
    refute result.blank?, msg
  end

  def assert_has_descendent ancestor, kind, filters = {}
    msg = proc {
      descendent = ax_search_id kind, filters
      "Expected #{ancestor.inspect} to have #{descendent} as a descendent"
    }
    refute check_descendent(ancestor,kind,filters).blank?, msg
  end

  def refute_has_child parent, kind, filters = {}
    msg = proc {
      child    = ax_search_id kind, filters
      "Expected #{parent.inspect} not to have #{child} as a child"
    }
    assert ax_check_children(parent,kind,filters).blank?, msg
  end

  def refute_has_descendent ancestor, kind, filters = {}
    msg = proc {
      descendent = ax_search_id kind, filters
      "Expected #{ancestor.inspect} not to have #{descendent} as a descendent"
    }
    assert ax_check_descendent(ancestor,kind,filters).blank?, msg
  end


  private

  def ax_search_id kind, filters
    filter = filters.empty? ? ::EMPTY_STRING : "(#{filters.inspect})"
    "#{kind}#{filter}"
  end

  def ax_check_children parent, kind, filters
    q = Accessibility::Qualifier.new(kind, filters)
    parent.attribute(:children).find { |x| q.qualifies? x }
  end

  def ax_check_descendent ancestor, kind, filters
    ancestor.search(kind, filters)
  end

end

# @todo assertions for minitest/spec
