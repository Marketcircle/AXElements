class TestAccessibilityQualifier < MiniTest::Unit::TestCase

  def app
    AX::Application.new REF
  end

  def qualifier klass, criteria, &block
    Accessibility::Qualifier.new(klass, criteria, &block)
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

  def test_qualifiers_can_use_aliased_attributes
    id = "I'm a little teapot"
    q = qualifier(:Button, id: id)
    app.main_window.children.each do |kid|
      if kid.attributes.include?(:identifier) && kid.id == id
        assert q.qualifies? kid
      else
        refute q.qualifies? kid
      end
    end
  end

  def test_qualifies_based_on_given_block
    @got_called = 0
    q = qualifier(:DockItem, {}) do |element|
      @got_called += 1
      element.subrole == KAXTrashDockItemSubrole
    end
    refute q.qualifies?(items.first), @got_called
    assert q.qualifies?(items.last), @got_called
    assert_equal 2, @got_called
  end

  def test_describe
    def describe expected, qualifier
      assert_equal expected, qualifier.describe
    end
    describe 'DockItem',                                     qualifier(:DockItem,{                                         }               )
    describe 'Button(title: "Free Bacon")',                  qualifier(:Button,  { title: 'Free Bacon'                     }               )
    describe 'Element[✔]',                                   qualifier(:Element, {                                         }, &proc { |_| })
    describe 'Window(id: /FindMe/, button(title: "Press"))', qualifier(:Window,  { id: /FindMe/, button: { title: 'Press' }}               )
    describe 'Row(id: "Yo")[✔]',                             qualifier(:Row,       id: 'Yo',                                  &proc { |_| })
  end

  # n is the number of filters used
  def bench_filters
    skip 'TODO'
  end

  # n is the number of elements compared
  def bench_similar_elements
    skip 'TODO'
    q = qualifier(:DockItem, title: 'Finder')
    assert_performance_linear do |n|
      (items * n).each { |item| q.qualifies? item }
    end
  end

end
