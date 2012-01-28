class TestAccessibilityStringParser < MiniTest::Unit::TestCase

  def dymap
    @@mapping ||= KeyCodeGenerator.dynamic_mapping
  end

  def parser
    Accessibility::Core::StringParser.new
  end

  def test_dynamic_map_initialized
    refute_empty Accessibility::Core::StringParser::MAPPING
  end

  def test_parse_dynamic
    h = dymap['h']
    a = dymap['a']
    i = dymap['i']
    expected = [[h, true],[h,false],[a,true],[a,false],[i,true],[i,false]]
    assert_equal expected, parser.parse('hai')
  end

  def test_parse_alt
    h = dymap['h']
    i = dymap['i']
    expected = [[56,true],[h,true],[h,false],[56,false],[56,true],[i,true],[i,false],[56,false]]
    assert_equal expected, parser.parse('HI')
  end

  def test_parse_escapes
    expected = [[42, true], [42, false]]
    actual   = parser.parse("\\")
    assert_equal expected, actual

    expected = [[0x7C, true], [0x7C, false]]
    actual   = parser.parse("\\->")
    assert_equal expected, actual
  end

  def test_parses_backslash
    expected = [[dymap["\\"], true], [dymap["\\"], false]]
    assert_equal expected, parser.parse("\\")
  end

  def test_parses_newline
    expected = [[dymap["\r"], true], [dymap["\r"], false]]
    assert_equal expected, parser.parse("\n")
  end

end
