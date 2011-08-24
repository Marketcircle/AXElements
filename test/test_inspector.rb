# -*- coding: utf-8 -*-

class TestPPInspector < MiniTest::Unit::TestCase
  include Accessibility::PPInspector

  # expected API for PPInspector module
  def attributes    ; @attributes end
  def attribute attr; @attribute  end
  def size_of   attr; @size_of    end

  # trivial but important for backwards compat with Snow Leopard
  def test_identifier_const
    assert Accessibility::PPInspector.const_defined? :KAXIdentifierAttribute
    assert_equal 'AXIdentifier', KAXIdentifierAttribute
  end

  def test_identifier_using_value
    @attributes = [KAXValueAttribute]

    @attribute  = 'cake'
    assert_match /cake/, pp_identifier

    @attribute  = 3.14
    assert_match /value=3.14/, pp_identifier

    @attribute  = ''
    assert_match NSString.string, pp_identifier
  end

  def test_identifier_using_title
    @attributes = [KAXTitleAttribute]
    @attribute  = 'My Title'
    assert_match /"My Title"/, pp_identifier
  end

  def test_identifier_using_title_ui_element
    @attributes = [KAXTitleUIElementAttribute]
    @attribute  = 'hey'
    assert_match /"hey"/, pp_identifier
  end

  # hmmm...
  def test_identifier_using_description
    @attributes = [KAXDescriptionAttribute]

    @attribute  = 'roflcopter'
    assert_match /roflcopter/, pp_identifier

    @attribute  = NSString.string
    assert_equal NSString.string, pp_identifier
  end

  def test_identifier_using_identifier
    @attributes = [KAXIdentifierAttribute]

    @attribute  = '_NS:151'
    assert_match /_NS:151/, pp_identifier

    @attribute  = 'contact table'
    assert_match /contact table/, pp_identifier
  end

  def test_identifier_empty_string_as_final_fallback
    @attributes = NSArray.array
    assert_equal NSString.string, pp_identifier
  end

  def test_position
    @attribute = CGPointZero
    assert_match /\(0\.0, 0\.0\)/, pp_position

    @attribute = CGPoint.new(3.14, -5)
    assert_match /\(3\.14, -5\.0\)/, pp_position
  end

  def test_children_pluralizes_properly
    @size_of = 2
    assert_match /2 children/, pp_children

    @size_of = 9001
    assert_match /9001 children/, pp_children

    @size_of = 3.14
    assert_match /3.14 children/, pp_children
  end

  def test_children_count
    @size_of = 1
    assert_match /1 child/, pp_children
  end

  def test_children_void_if_none
    @size_of = 0
    assert_equal NSString.string, pp_children
  end

  def test_checkbox_includes_attribute_name_and_box
    @attribute = true
    assert_match /thing\[.\]/, pp_checkbox(:thing)
    assert_match /cake\[.\]/,  pp_checkbox(:cake)
    assert_match /pie\[.\]/,   pp_checkbox(:pie)
  end

  def test_checkbox_uses_checks_properly
    check = /✔/
    cross = /✘/

    @attribute = true
    assert_match check, pp_checkbox(:a)

    @attribute = :cake
    assert_match check, pp_checkbox(:a)

    @attribute = false
    assert_match cross, pp_checkbox(:a)

    @attribute = nil
    assert_match cross, pp_checkbox(:a)
  end

end
