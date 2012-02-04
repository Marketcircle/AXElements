# -*- coding: utf-8 -*-

class TestAccessibilityPPInspector < MiniTest::Unit::TestCase
  include Accessibility::PPInspector

  # expected API for PPInspector module
  attr_reader :attributes
  def attribute attr; @attribute; end
  def size_of   attr; @size_of;   end

  def test_identifier_using_value
    @attributes = [:value]

    @attribute  = 'cake'
    assert_match /"cake"/, pp_identifier

    @attribute  = 3.14
    assert_match /value=3.14/, pp_identifier

    @attribute  = ''
    assert_match ::EMPTY_STRING, pp_identifier

    @attribute  = nil
    assert_match ::EMPTY_STRING, pp_identifier
  end

  def test_identifier_using_title
    @attributes = [:title]
    @attribute  = 'My Title'
    assert_match /"My Title"/, pp_identifier
  end

  def test_identifier_using_title_ui_element
    @attributes = [:title_ui_element]
    @attribute  = 'hey'
    assert_match /"hey"/, pp_identifier
  end

  # hmmm...
  def test_identifier_using_description
    @attributes = [:description]

    @attribute  = 'roflcopter'
    assert_match /roflcopter/, pp_identifier

    @attribute  = NSString.string
    assert_equal ::EMPTY_STRING, pp_identifier

    @attribute  = 26
    assert_match /26/, pp_identifier
  end

  def test_identifier_using_identifier
    @attributes = [:identifier]

    @attribute  = '_NS:151'
    assert_match /id=_NS:151/, pp_identifier

    @attribute  = 'contact table'
    assert_match /id=contact table/, pp_identifier
  end

  def test_identifier_empty_string_as_final_fallback
    @attributes = NSArray.array
    assert_equal ::EMPTY_STRING, pp_identifier
  end

  def test_position
    @attribute = CGPointZero
    assert_match /\(0\.0, 0\.0\)/, pp_position

    @attribute = CGPoint.new(3.14, -5)
    assert_match /\(3\.14, -5\.0\)/, pp_position
  end

  # this sometimes happens, even though it shouldn't
  def test_position_is_nil
    @attribute = nil
    assert_equal ::EMPTY_STRING, pp_position
  end

  def test_children_pluralizes_properly
    [[2,    /2 children/   ],
     [9001, /9001 children/],
     [3.14, /3.14 children/],
     [1,    /1 child/      ],
     [0,    ::EMPTY_STRING ]
    ].each do |size, matcher|
      @size_of = size
      assert_match matcher, pp_children
    end
  end

  def test_checkbox
    @attribute = true
    assert_match /thing\[✔\]/, pp_checkbox(:thing)
    @attribute = false
    assert_match /thing\[✘\]/, pp_checkbox(:thing)
    @attribute = nil
    assert_match /thing\[✘\]/, pp_checkbox(:thing)

    @attribute = true
    assert_match /some attr\[✔\]/, pp_checkbox('some attr')
    @attribute = false
    assert_match /some attr\[✘\]/, pp_checkbox('some attr')
    @attribute = nil
    assert_match /some attr\[✘\]/, pp_checkbox('some attr')
  end

end
