class TestAccessibilityStringParser < MiniTest::Unit::TestCase
  include Accessibility::StringParser

  # key code for the left shift key
  def shift
    56
  end

  def dymap
    @@mapping ||= KeyCodeGenerator.dynamic_mapping
  end

  def test_dynamic_map_initialized
    refute_empty Accessibility::StringParser::MAPPING
  end

  def test_parsing_uppercase
    h = dymap['h']
    i = dymap['i']
    expected = [[shift,true],[h,true],[h,false],[shift,false],
                [shift,true],[i,true],[i,false],[shift,false]]
    actual   = create_events_for 'HI'
    assert_equal expected, actual
  end

  def test_parsing_numbers
    four = dymap['4']
    two  = dymap['2']
    expected = [[four,true],[four,false],[two,true],[two,false]]
    actual   = create_events_for '42'
    assert_equal expected, actual
  end

  def test_parsing_lowercase
    c = dymap['c']
    a = dymap['a']
    k = dymap['k']
    e = dymap['e']
    expected = [[c,true],[c,false],[a,true],[a,false],[k,true],[k,false],[e,true],[e,false]]
    actual   = create_events_for 'cake'
    assert_equal expected, actual
  end

  def test_parsing_ruby_escapes
    retern = dymap["\r"]
    expected = [[retern,true],[retern,false]]
    actual   = create_events_for "\r"
    assert_equal expected, actual

    actual   = create_events_for "\n"
    assert_equal expected, actual

    tab = dymap["\t"]
    expected = [[tab,true],[tab,false]]
    actual   = create_events_for "\t"
    assert_equal expected, actual

    space = dymap["\s"]
    expected = [[space,true],[space,false]]
    actual = create_events_for "\s"
    assert_equal expected, actual

    actual = create_events_for ' '
    assert_equal expected, actual
  end

  def test_parsing_symbols
    dash = dymap['-']
    expected = [[dash,true],[dash,false]]
    actual   = create_events_for '-'
    assert_equal expected, actual

    comma = dymap[',']
    expected = [[comma,true],[comma,false]]
    actual   = create_events_for ","
    assert_equal expected, actual

    apostrophe = dymap["'"]
    expected = [[apostrophe,true],[apostrophe,false]]
    actual   = create_events_for "'"
    assert_equal expected, actual

    bang  = dymap['1']
    expected = [[shift,true],[bang,true],[bang,false],[shift,false]]
    actual   = create_events_for '!'
    assert_equal expected, actual

    at    = dymap['2']
    expected = [[shift,true],[at,true],[at,false],[shift,false]]
    actual   = create_events_for '@'
    assert_equal expected, actual

    paren = dymap['9']
    expected = [[shift,true],[paren,true],[paren,false],[shift,false]]
    actual   = create_events_for '('
    assert_equal expected, actual

    chev  = dymap[',']
    expected = [[shift,true],[chev,true],[chev,false],[shift,false]]
    actual   = create_events_for "<"
    assert_equal expected, actual
  end

  def test_parsing_backslashes
    backslash = dymap["\\"]
    expected = [[backslash,true],[backslash,false]]
    actual   = create_events_for "\\"
    assert_equal expected, actual
  end

  def test_parsing_custom_escapes
    command = 0x37
    expected = [[command,true],[command,false]]
    actual   = create_events_for "\\COMMAND"
    assert_equal expected, actual

    rarrow  = 0x7c
    expected = [[command,true],
                  [shift,true],
                    [rarrow,true],
                    [rarrow,false],
                  [shift,false],
                [command,false]]
    actual   = create_events_for "\\COMMAND+\\SHIFT+\\->"
    assert_equal expected, actual
  end

end
