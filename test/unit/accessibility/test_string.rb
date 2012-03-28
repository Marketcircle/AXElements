# -*- coding: utf-8 -*-

require 'accessibility/string'

class TestAccessibilityStringLexer < MiniTest::Unit::TestCase

  def lexer
    Accessibility::String::Lexer
  end

  def test_lex_simple_string
    assert_equal [],                                                    lexer.new('').lex
    assert_equal ['"',"J","u","s","t"," ","W","o","r","k","s",'"',"™"], lexer.new('"Just Works"™').lex
    assert_equal ["M","i","l","k",","," ","s","h","a","k","e","."],     lexer.new("Milk, shake.").lex
    assert_equal ["D","B","7"],                                         lexer.new("DB7").lex
  end

  def test_lex_single_custom_escape
    assert_equal ["\\CMD"], lexer.new("\\CMD").lex
    assert_equal ["\\+"],   lexer.new("\\+").lex
    assert_equal ["\\1"],   lexer.new("\\1").lex
    assert_equal ["\\F1"],  lexer.new("\\F1").lex
  end

  def test_lex_hotkey_custom_escape
    assert_equal ["\\COMMAND",[","]],             lexer.new("\\COMMAND+,").lex
    assert_equal ["\\COMMAND",["\\SHIFT",["s"]]], lexer.new("\\COMMAND+\\SHIFT+s").lex
    assert_equal ["\\COMMAND",["\\+"]],           lexer.new("\\COMMAND+\\+").lex
    assert_equal ["\\FN",["\\F10"]],              lexer.new("\\FN+\\F10").lex
  end

  def test_lex_ruby_escapes
    assert_equal ["\n","\r","\t","\b"],                                lexer.new("\n\r\t\b").lex
    assert_equal ["O","n","e","\n","T","w","o"],                       lexer.new("One\nTwo").lex
    assert_equal ["L","i","e","\b","\b","\b","d","e","l","i","s","h"], lexer.new("Lie\b\b\bdelish").lex
  end

  def test_lex_complex_string
    assert_equal ["T","e","s","t","\\CMD",["s"]],                          lexer.new("Test\\CMD+s").lex
    assert_equal ["Z","O","M","G"," ","1","3","3","7","!","!","1"],        lexer.new("ZOMG 1337!!1").lex
    assert_equal ["F","u","u","!","@","#","%","\\CMD",["a"],"\b"],         lexer.new("Fuu!@#%\\CMD+a \b").lex
    assert_equal ["\\CMD",["a"],"\b","A","l","l"," ","g","o","n","e","!"], lexer.new("\\CMD+a \bAll gone!").lex
  end

  def test_lex_backslash # make sure we handle these edge cases predictably
    assert_equal ["\\"],             lexer.new("\\").lex
    assert_equal ["\\"," "],         lexer.new("\\ ").lex
    assert_equal ["\\","h","m","m"], lexer.new("\\hmm").lex
    assert_equal ["\\HMM"],          lexer.new("\\HMM").lex
  end

  def test_lex_bad_custom_escape_sequence
    assert_raises ArgumentError do
      lexer.new("\\COMMAND+").lex
    end
  end

end


class TestAccessibilityStringEventGenerator < MiniTest::Unit::TestCase

  def setup
    skip
  end

  def generator
    Accessibility::String::EventGenerator
  end

  def generate *tokens
    generator.new(tokens).generate.events
  end

  # key code for the left shift key
  def shift_down; [56,true];  end
  def shift_up;   [56,false]; end

  # key code for the left option key
  def option_down; [58,true];  end
  def option_up;   [58,false]; end

  def map
    @@map ||= KeyCoder.dynamic_mapping
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
    actual   = generate ","
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

    expected = [shift_down,[chev,true],[chev,false],shift_up]
    actual   = generate '>'
    assert_equal expected, actual
  end

  def test_generate_unicode # holding option
    sigma, tm, gbp, omega = map.values_at 'w', '2', '3', 'z'

    expected = [option_down, [sigma,true],[sigma,false], option_up]
    actual   = generate '∑'
    assert_equal expected, actual

    expected = [option_down, [tm,true],[tm,false], option_up]
    actual   = generate '™'
    assert_equal expected, actual

    expected = [option_down, [gbp,true],[gbp,false], option_up]
    actual   = generate '£'
    assert_equal expected, actual

    expected = [option_down, [omega,true],[omega,false], option_up]
    actual   = generate 'Ω'
    assert_equal expected, actual
  end

  def test_generate_backslashes
    backslash, space, h, m =
      map.values_at "\\", ' ', 'h', 'm'

    expected = [[backslash,true],[backslash,false]]
    actual   = generate "\\"
    assert_equal expected, actual

    expected = [[backslash,true],[backslash,false],
                [space,true],[space,false]]
    actual   = generate "\\",' '
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
                shift_down,[m,true],[m,false],shift_up,
                shift_down,[m,true],[m,false],shift_up]
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
    right_arrow = 0x7c
    command     = 0x37
    expected = [[command,true],
                  shift_down,
                    [right_arrow,true],
                    [right_arrow,false],
                  shift_up,
                [command,false]]
    actual   = generate ['\COMMAND',['\SHIFT',['\->']]]
    assert_equal expected, actual
  end

  def test_generate_after_hotkey
    ctrl, a, space, h, i = 0x3B, *map.values_at('a',' ','h','i')
    expected = [[ctrl,true],
                 [a,true],[a,false],
                [ctrl,false],
                [space,true],[space,false],
                [h,true],[h,false],[i,true],[i,false]
               ]
    actual   = generate ['\CTRL',['a']], ' ', 'h', 'i'
    assert_equal expected, actual
  end

  def test_bails_for_unmapped_token
    assert_raises ArgumentError do
      generate '☃'
    end
  end

  def test_generation_is_idempotent
    g = generator.new(['M'])
    original_events = g.generate.events.dup
    new_events      = g.generate.events
    assert_equal original_events, new_events
  end

end


class TestAccessibilityString < MiniTest::Unit::TestCase
  include Accessibility::String

  # hmmmmm....
  def test_events_for_regular_case
    events = keyboard_events_for 'cheezburger'
    assert_kind_of Array, events
    refute_empty events

    assert_kind_of Array, events[0]
    assert_kind_of Array, events[1]
  end

  def test_dynamic_map_initialized
    refute_empty Accessibility::String::EventGenerator::MAPPING
  end

  def test_alias_is_included
    map = Accessibility::String::EventGenerator::MAPPING
    assert_equal map["\r"], map["\n"]
  end

  def test_can_parse_empty_string
    assert_equal [], keyboard_events_for('')
  end

end
