class TestAccessibilityStringLexer < MiniTest::Unit::TestCase

  def lexer
    skip
    Accessibility::String::Lexer
  end

  def test_lex_method_chaining
    l = lexer.new ''
    assert_kind_of lexer, l.lex
  end

  def test_lex_single_custom
    l = lexer.new('\CMD').lex
    assert_equal [['\CMD']], l.tokens
  end

  def test_lex_hotkey_custom
    l = lexer.new('\COMMAND+,').lex
    assert_equal [['\COMMAND',',']], l.tokens
  end

  def test_lex_multiple_custom
    l = lexer.new('\COMMAND+\SHIFT+s').lex
    assert_equal [['\COMMAND','\SHIFT','s']], l.tokens
  end

  def test_lex_simple_string
    l = lexer.new('"It Just Works"™').lex
    assert_equal ['"','I','t',' ','J','u','s','t',' ','W','o','r','k','s','"','™'], l.tokens

    l = lexer.new('Martini, shaken.').lex
    assert_equal ['M','a','r','t','i','n','i',',',' ','s','h','a','k','e','n','.'], l.tokens

    l = lexer.new('Aston Martin DB7').lex
    assert_equal ['A','s','t','o','n',' ','M','a','r','t','i','n',' ','D','B','7'], l.tokens
  end

  def test_lex_ruby_escapes
    l = lexer.new("The cake is a lie\b\b\bdelicious").lex
    assert_equal ['T','h','e',' ','c','a','k','e',' ','i','s',' ','a',' ','l','i','e',"\b","\b","\b",'d','e','l','i','c','i','o','u','s'], l.tokens
  end

  def test_lex_complex_string
    l = lexer.new("\\COMMAND+a \bI deleted your text, lol!").lex
    assert_equal [['\COMMAND','a'],"\b",'I',' ','d','e','l','e','t','e','d',' ','y','o','u','r',' ','t','e','x','t',',',' ','l','o','l','!'], l.tokens
  end

  def test_lex_backspace
    l = lexer.new("\\").lex
    assert_equal ["\\"], l.tokens

    l = lexer.new('\ ').lex
    assert_equal ["\\",' '], l.tokens

    l = lexer.new('\hmm').lex
    assert_equal ["\\",'h','m','m'], l.tokens

    # is this the job of the parser or the lexer?
    l = lexer.new('\HMM').lex
    assert_equal [["\\HMM"]], l.tokens
  end

  def test_lex_bad_custom_seq
    l = lexer.new('\COMMAND+')
    assert_equal [['\COMMAND']], l.tokens
  end

end


class TestAccessibilityStringEventGenerator < MiniTest::Unit::TestCase

  def generate *tokens
    skip
    Accessibility::String::EventGenerator.new(tokens).events
  end

  # key code for the left shift key
  def shift_down
    [56,true]
  end

  def shift_up
    [56,false]
  end

  def map
    @@map ||= KeyCodeGenerator.dynamic_mapping
  end

  def test_generate_lowercase
    c, a, k, e = map.values_at 'c', 'a', 'k', 'e'
    expected = [[c,true],[c,false],
                [a,true],[a,false],
                [k,true],[k,false],
                [e,true],[e,false]]
    actual   = generate 'c', 'a', 'k', 'e'
    assert_equal expected, actual
  end

  def test_generate_uppercase
    h, i = map.values_at 'h', 'i'
    expected = [shift_down,[h,true],[h,false],shift_up,
                shift_down,[i,true],[i,false],shift_up]
    actual   = generate 'H', 'I'
    assert_equal expected, actual
  end

  def test_generate_numbers
    two, four = map.values_at '2', '4'
    expected  = [[four,true],[four,false],[two,true],[two,false]]
    actual    = generate '4', '2'
    assert_equal expected, actual
  end

  def test_generate_ruby_escapes
    retern, tab, space = map.values_at "\r", "\t", "\s"

    expected = [[retern,true],[retern,false]]
    actual   = generate "\r"
    assert_equal expected, actual

    expected = expected
    actual   = generate "\n"
    assert_equal expected, actual

    expected = [[tab,true],[tab,false]]
    actual   = generate "\t"
    assert_equal expected, actual

    expected = [[space,true],[space,false]]
    actual   = generate "\s"
    assert_equal expected, actual

    expected = expected
    actual   = generate ' '
    assert_equal expected, actual
  end

  def test_generate_symbols
    dash, comma, apostrophe, bang, at, paren, chev =
     map.values_at '-', ',', "'", '1', '2', '9', '.'

    expected = [[dash,true],[dash,false]]
    actual   = generate '-'
    assert_equal expected, actual

    expected = [[comma,true],[comma,false]]
    actual   = create_events_for ","
    assert_equal expected, actual

    expected = [[apostrophe,true],[apostrophe,false]]
    actual   = generate "'"
    assert_equal expected, actual

    expected = [shift_down,[bang,true],[bang,false],shift_up]
    actual   = generate '!'
    assert_equal expected, actual

    expected = [shift_down,[at,true],[at,false],shift_up]
    actual   = generate '@'
    assert_equal expected, actual

    expected = [shift_down,[paren,true],[paren,false],shift_up]
    actual   = generate '('
    assert_equal expected, actual

    expected = [[shift,true],[chev,true],[chev,false],shift_up]
    actual   = generate '>'
    assert_equal expected, actual
  end

  def test_generate_unicode # holding option
    sigma, tm, gbp, omega = map.values_at 'w', '2', '3', 'z'

    expected = [[sigma,true],[sigma,false]]
    actual   = generate '∑'
    assert_equal expected, actual

    expected = [[tm,true],[tm,false]]
    actual   = generate '™'
    assert_equal expected, actual

    expected = [[gbp,true],[gbp,false]]
    actual   = generate '£'
    assert_equal expected, actual

    expected = [[omega,true],[omega,false]]
    actual   = generate 'Ω'
    assert_equal expected, actual
  end

  def test_generate_backslashes
    backslash, space, h, m =
      map.values_at "\\", ' ', 'h', 'm'

    expected = [[backslash,true],[backslash,false]]
    actual   = generate ["\\"]
    assert_equal expected, actual

    expected = [[backslash,true],[backslash,false],
                [space,true],[space,false]]
    actual   = generate ["\\",' ']
    assert_equal expected, actual

    expected = [[backslash,true],[backslash,false],
                [h,true],[h,false],
                [m,true],[m,false],
                [m,true],[m,false]]
    actual   = generate "\\",'h','m','m'
    assert_equal expected, actual

    # is this the job of the parser or the lexer?
    expected = [[backslash,true],[backslash,false],
                shift_down,[h,true],[h,false],shift_up,
                shift_down,[m,true],[h,false],shift_up,
                shift_down,[m,true],[h,false],shift_up]
    actual   = generate ["\\HMM"]
    assert_equal expected, actual
  end

  def test_generate_a_custom_escape
    command  = 0x37
    expected = [[command,true],[command,false]]
    actual   = generate ['\COMMAND']
    assert_equal expected, actual
  end

  def test_generate_hotkey
    skip
    right_arrow = 0x7c
    expected = [[command,true],
                  shift_down,
                    [right_arrow,true],
                    [right_arrow,false],
                  shift_up,
                [command,false]]
    actual   = generate ['\COMMAND','\SHIFT','\->']
    assert_equal expected, actual
  end

  def test_bails_for_unmapped_token
    assert_raises ArgumentError do
      generate '☃'
    end
  end

end


class TestAccessibilityString < MiniTest::Unit::TestCase
  #include Accessibility::String

  def test_exposed
    skip
    assert_respond_to self, :events_for
  end

  def test_dynamic_map_initialized
    skip
    refute_empty Accessibility::String::MAPPING
  end

  def test_alias_is_included
    skip
    map = Accessibility::String::MAPPING
    assert_equal map["\r"], map["\n"]
  end

  def test_can_parse_empty_string
    assert_block do
      events_for ''
    end
  end

end

