class TestAccessibilityQualifier < MiniTest::Unit::TestCase

  def app
    AX::Application.new REF
  end

  def qualifier klass, criteria
    Accessibility::Qualifier.new(klass, criteria)
  end

  def dock
    AX::DOCK
  end

  def list
    @@list ||= dock.children.first
  end

  def items
    @@items ||= list.children
  end

  def test_qualifies_based_on_class
    q = qualifier(:List, {})
    assert q.qualifies? list
    refute q.qualifies? items.sample
  end

  def test_qualifies_based_on_superclass
    q = qualifier(:DockItem, {})
    items.each do |item|
      assert q.qualifies? item
    end

    refute q.qualifies? dock
  end

  def test_qualifies_based_on_non_existant_class
    q = qualifier(:Derp, {})
    refute q.qualifies? dock
    refute q.qualifies? list
    refute q.qualifies? items.sample
  end

  def test_qualifies_based_on_attribute_filter
    q = qualifier(:DockItem, title: 'Trash')
    trash  = items.find { |item| item.class == AX::TrashDockItem }
    others = items.select { |item| item != trash }

    assert q.qualifies? trash
    others.each do |other|
      refute q.qualifies? other
    end
  end

  def test_qualifies_based_on_regexp_match
    q = qualifier(:DockItem, title: /Trash/)
    trash  = items.find { |item| item.class == AX::TrashDockItem }
    others = items.select { |item| item != trash }

    assert q.qualifies? trash
    others.each do |other|
      refute q.qualifies? other
    end
  end

  def test_qualifies_based_on_subsearch
    q = qualifier(:List, dock_item: { title: 'Trash' })
    assert q.qualifies? list
    refute q.qualifies? dock
    refute q.qualifies? items.sample
  end

  def test_qualifies_based_on_param_attribute_value
    e = app.attribute(:main_window).attribute(:title_ui_element)
    q = qualifier(:StaticText, [:string_for_range, CFRange.new(0,2)] => 'AX' )
    assert q.qualifies? e
    refute q.qualifies? list
  end

  def test_qualifies_based_on_param_attribute_regexp_match
    e = app.attribute(:main_window).attribute(:title_ui_element)
    q = qualifier(:StaticText, [:string_for_range, CFRange.new(0,2)] => /AX/ )
    assert q.qualifies? e
    refute q.qualifies? items.sample
  end

  def test_qualifies_based_on_multiple_filters
    q = qualifier(:DockItem, title: 'Trash', role_description: /trash dock item/)
    assert q.qualifies? items.last
    refute q.qualifies? items.first

    q = qualifier(:List, role_description: /list/, trash_dock_item: { title: 'Trash' })
    assert q.qualifies? list
    refute q.qualifies? items.sample
  end

end
