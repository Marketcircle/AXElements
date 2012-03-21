# -*- coding: utf-8 -*-

require   'accessibility/version'
require   'accessibility/key_coder'
framework 'ApplicationServices' if defined? MACRUBY_REVISION

##
# Parses strings of human readable text into a series of events meant to
# be processed by {Accessibility::Core#post:to:}.
#
# Supports most, if not all, latin keyboard layouts, maybe some
# international layouts as well.
module Accessibility::String


  private

  # @param [String]
  # @return [Array<Array(Fixnum,Boolean)>]
  def keyboard_events_for string
    EventGenerator.new(Lexer.new(string).lex.tokens).generate.events
  end

  ##
  # Tokenizer for strings. This class will take a string and break
  # it up into chunks for the event generator. The structure generated
  # here is an array that contains strings and recursively other arrays
  # of strings and arrays of strings.
  #
  # @example
  #
  #   Lexer.new('Hai').lex.tokens        # => ['H','a','i']
  #   Lexer.new('\CAPSLOCK').lex.tokens  # => [['\CAPSLOCK']]
  #   Lexer.new('\COMMAND+a').lex.tokens # => [['\COMMAND', ['a']]]
  #   Lexer.new("One\nTwo").lex.tokens   # => ['O','n','e',"\n",'T','w','o']
  #
  class Lexer

    ##
    # Once a string is lexed, this contains the tokenized structure.
    #
    # @return [Array<String,Array<self>]
    attr_accessor :tokens

    # @param [String]
    def initialize string
      @chars  = string
      @tokens = []
      @index  = 0
    end

    ##
    # Tokenize the string that the lexer was initialized with.
    #
    # @return [self]
    def lex
      while @chars[@index]
        char     = @chars[@index]
        @tokens << if custom? char
                     lex_custom
                   else
                     char
                   end
        @index += 1
      end
      self
    end


    private

    def lex_custom
      start_index = @index
      while true
        case char = @chars[@index]
        when SPACE, nil
          return [@chars[start_index...@index]]
        when PLUS
          custom = [@chars[start_index...@index]]
          @index += 1
          return custom << lex_custom
        else
          @index += 1
        end
      end
    end

    ##
    # Is it a real custom escape? Kind of a lie, there is one
    # case it does not handle--an upper case letter or symbol
    # following `"\\"`. Eventually I will need to handle these...
    def custom? char
      char == CUSTOM_ESCAPE &&
        (next_char = @chars[@index+1]) &&
         next_char == next_char.upcase &&
         next_char != SPACE
    end

    # @private
    SPACE         = ' '
    # @private
    PLUS          = '+'
    # @private
    CUSTOM_ESCAPE = "\\"
  end


  ##
  # @todo Add a method to generate just keydown or just keyup events.
  #
  # Generate a sequence of keyboard events given a sequence of tokens.
  #
  # @example
  #
  #   EventGenerator.new(['H','a','i']).generate.events
  #       # => [[56,true],[80,true],[80,false],[56,false],[70,true],[70,false],[111,true],[111,false]]
  #   EventGenerator.new([['\CAPS']]).generate.events
  #       # => [[0x39,true],[0x39,false]]
  #   EventGenerator.new([['\CMD',['a']]]).generate.events
  #       # => [[0x37,true],[50,true],[50,false],[0x37,false]]
  #   EventGenerator.new(['O',"\n",'t']).generate.events
  #       # => [[56,true],[10,true],[10,false],[56,false],[45,true],[45,false],[92,true],[92,false]]
  #
  class EventGenerator

    ##
    # Regenerate the portion of the key mapping that is set dynamically
    # based on keyboard layout (e.g. US, Dvorak, etc.).
    #
    # This method should be called whenever the keyboard layout changes.
    # This can be called automatically by registering for a notification
    # in a run looped environment.
    def self.regenerate_dynamic_mapping
      # KeyCodeGenerator is declared in the Objective-C extension
      MAPPING.merge! KeyCodeGenerator.dynamic_mapping
      # Also add an alias to the mapping
      MAPPING["\n"] = MAPPING["\r"]
    end

    ##
    # Dynamic mapping of characters to keycodes. The map is generated at
    # startup time in order to support multiple keyboard layouts.
    #
    # @return [Hash{String=>Fixnum}]
    MAPPING = {}

    ##
    # @note These mappings are all static and come from `/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h`
    #
    # Map of custom escape sequences to their hardcoded keycode value.
    #
    # @return [Hash{String=>Fixnum}]
    CUSTOM = {
      'ESCAPE'          => 0x35,
      'ESC'             => 0x35,
      'COMMAND'         => 0x37,
      'CMD'             => 0x37,
      'SHIFT'           => 0x38,
      'LSHIFT'          => 0x38,
      'CAPS'            => 0x39,
      'CAPSLOCK'        => 0x39,
      'OPTION'          => 0x3A,
      'OPT'             => 0x3A,
      'ALT'             => 0x3A,
      'CONTROL'         => 0x3B,
      'CTRL'            => 0x3B,
      'RSHIFT'          => 0x3C,
      'ROPTION'         => 0x3D,
      'ROPT'            => 0x3D,
      'RALT'            => 0x3D,
      'RCONTROL'        => 0x3E,
      'RCTRL'           => 0x3E,
      'FUNCTION'        => 0x3F,
      'FN'              => 0x3F,
      'VOLUMEUP'        => 0x48,
      'VOLUP'           => 0x48,
      'VOLUMEDOWN'      => 0x49,
      'VOLDOWN'         => 0x49,
      'MUTE'            => 0x4A,
      'F1'              => 0x7A,
      'F2'              => 0x78,
      'F3'              => 0x63,
      'F4'              => 0x76,
      'F5'              => 0x60,
      'F6'              => 0x61,
      'F7'              => 0x62,
      'F8'              => 0x64,
      'F9'              => 0x65,
      'F10'             => 0x6D,
      'F11'             => 0x67,
      'F12'             => 0x6F,
      'F13'             => 0x69,
      'F14'             => 0x6B,
      'F15'             => 0x71,
      'F16'             => 0x6A,
      'F17'             => 0x40,
      'F18'             => 0x4F,
      'F19'             => 0x50,
      'F20'             => 0x5A,
      'HELP'            => 0x72,
      'HOME'            => 0x73,
      'END'             => 0x77,
      'PAGEUP'          => 0x74,
      'PAGEDOWN'        => 0x79,
      'DELETE'          => 0x75,
      'LEFT'            => 0x7B,
      '<-'              => 0x7B,
      'RIGHT'           => 0x7C,
      '->'              => 0x7C,
      'DOWN'            => 0x7D,
      'UP'              => 0x7E,
      '0'               => 0x52,
      '1'               => 0x53,
      '2'               => 0x54,
      '3'               => 0x55,
      '4'               => 0x56,
      '5'               => 0x57,
      '6'               => 0x58,
      '7'               => 0x59,
      '8'               => 0x5B,
      '9'               => 0x5C,
      'Decimal'         => 0x41,
      '.'               => 0x41,
      'Plus'            => 0x45,
      '+'               => 0x45,
      'Multiply'        => 0x43,
      '*'               => 0x43,
      'Minus'           => 0x4E,
      '-'               => 0x4E,
      'Divide'          => 0x4B,
      '/'               => 0x4B,
      'Equals'          => 0x51,
      '='               => 0x51,
      'Enter'           => 0x4C,
      'Clear'           => 0x47,
    }

    ##
    # Mapping of shifted (characters written when holding shift) characters
    # to keycodes.
    #
    # @return [Hash{String=>Fixnum}]
    SHIFTED = {
      '~'               => '`',
      '!'               => '1',
      '@'               => '2',
      '#'               => '3',
      '$'               => '4',
      '%'               => '5',
      '^'               => '6',
      '&'               => '7',
      '*'               => '8',
      '('               => '9',
      ')'               => '0',
      '{'               => '[',
      '}'               => ']',
      '?'               => '/',
      '+'               => '=',
      '|'               => "\\",
      ':'               => ';',
      '_'               => '-',
      '"'               => "'",
      '<'               => ',',
      '>'               => '.',
      'A'               => 'a',
      'B'               => 'b',
      'C'               => 'c',
      'D'               => 'd',
      'E'               => 'e',
      'F'               => 'f',
      'G'               => 'g',
      'H'               => 'h',
      'I'               => 'i',
      'J'               => 'j',
      'K'               => 'k',
      'L'               => 'l',
      'M'               => 'm',
      'N'               => 'n',
      'O'               => 'o',
      'P'               => 'p',
      'Q'               => 'q',
      'R'               => 'r',
      'S'               => 's',
      'T'               => 't',
      'U'               => 'u',
      'V'               => 'v',
      'W'               => 'w',
      'X'               => 'x',
      'Y'               => 'y',
      'Z'               => 'z',
    }

    ##
    # Mapping of optioned (characters written when holding option/alt)
    # characters to keycodes.
    #
    # @return [Hash{String=>Fixnum}]
    OPTIONED = {
      '¡'               => '1',
      '™'               => '2',
      '£'               => '3',
      '¢'               => '4',
      '∞'               => '5',
      '§'               => '6',
      '¶'               => '7',
      '•'               => '8',
      'ª'               => '9',
      'º'               => '0',
      '“'               => '[',
      '‘'               => ']',
      'æ'               => "'",
      '≤'               => ',',
      '≥'               => '.',
      'π'               => 'p',
      '¥'               => 'y',
      'ƒ'               => 'f',
      '©'               => 'g',
      '®'               => 'r',
      '¬'               => 'l',
      '÷'               => '/',
      '≠'               => '=',
      '«'               => "\\",
      'å'               => 'a',
      'ø'               => 'o',
      '´'               => 'e',
      '¨'               => 'u',
      'ˆ'               => 'i',
      '∂'               => 'd',
      '˙'               => 'h',
      '†'               => 't',
      '˜'               => 'n',
      'ß'               => 's',
      '–'               => '-',
      '…'               => ';',
      'œ'               => 'q',
      '∆'               => 'j',
      '˚'               => 'k',
      '≈'               => 'x',
      '∫'               => 'b',
      'µ'               => 'm',
      '∑'               => 'w',
      '√'               => 'v',
      'Ω'               => 'z',
    }


    ##
    # Once {generate} is called, this contains the sequence of
    # events.
    #
    # @return [Array<Array(Fixnum,Boolean)>]
    attr_reader :events

    # @param [Array<String,Array<String,Array...>>]
    def initialize tokens
      @tokens = tokens
      # *4 since the output array will be at least *2 the
      # number of tokens passed in, but will often be larger
      # due to shifted/optioned characters and custom escapes
      # though a better number could be derived from
      # analyzing common input...
      @events = Array.new tokens.size*4
    end

    ##
    # Generate the events for the tokens the event generator
    # was initialized with.
    #
    # @return [self]
    def generate
      @index = 0
      generate_all @tokens
      @events.compact!
      self
    end


    private

    def generate_all tokens
      tokens.each do |token|
        if token.kind_of? Array
          generate_custom token
        elsif SHIFTED.has_key? token
          generate_shifted token
        elsif OPTIONED.has_key? token
          generate_optioned token
        else
          generate_dynamic token
        end
      end
    end

    def generate_custom token
      code = CUSTOM.fetch token.first[1..-1], nil
      unless code
        generate_all token.first.split(EMPTY_STRING)
        return
      end

      @events[@index] = [code,true]
      @index += 1
      generate_all token[1..-1]
      @events[@index] = [code,false]
      @index += 1
    end

    def generate_shifted token
      @events[@index] = SHIFT_DOWN
      @index += 1
      generate_dynamic SHIFTED[token]
      @events[@index] = SHIFT_UP
      @index += 1
    end

    def generate_optioned token
      @events[@index] = OPTION_DOWN
      @index += 1
      generate_dynamic OPTIONED[token]
      @events[@index] = OPTION_UP
      @index += 1
    end

    def generate_dynamic token
      code = MAPPING.fetch token, nil
      raise ArgumentError, "#{token} has no mapping, bail!" unless code
      @events[@index]   = [code,true]
      @events[@index+1] = [code,false]
      @index += 2
    end

    # @private
    EMPTY_STRING  = ''
    # @private
    CUSTOM_ESCAPE = "\\"
    # @private
    OPTION_DOWN   = [58,true]
    # @private
    OPTION_UP     = [58,false]
    # @private
    SHIFT_DOWN    = [56,true]
    # @private
    SHIFT_UP      = [56,false]
  end

end


##
# @note This will only work if a run loop is running
#
# Register to be notified if the keyboard layout changes at runtime
# NSDistributedNotificationCenter.defaultCenter.addObserver Accessibility::String::EventGenerator,
#                                                selector: 'regenerate_dynamic_mapping',
#                                                    name: KTISNotifySelectedKeyboardInputSourceChanged,
#                                                  object: nil

# Initialize the table
Accessibility::String::EventGenerator.regenerate_dynamic_mapping
