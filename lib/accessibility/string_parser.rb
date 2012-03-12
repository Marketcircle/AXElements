require 'accessibility/key_code_generator'

##
# Parses strings of human readable text into a series of events meant to
# be processed by {Accessibility::Core#post:to:}.
#
# Supports most, if not all, latin keyboard layouts, maybe some
# international layouts as well.
module Accessibility::String

  ##
  # Regenerate the portion of the key mapping that is set dynamically based
  # on keyboard layout (e.g. US, Dvorak, etc.).
  #
  # This method should be called whenever the keyboard layout changes. If a run
  # loop is spinning then it will automatically be called.
  def self.regenerate_dynamic_mapping
    # KeyCodeGenerator is declared in the Objective-C extension
    MAPPING.merge! KeyCodeGenerator.dynamic_mapping
    MAPPING["\n"] = MAPPING["\r"]
  end


  private

  ##
  # @private
  #
  # Dynamic mapping of characters to keycodes. The map is generated at
  # startup time in order to support multiple keyboard layouts.
  #
  # @return [Hash{String=>Fixnum}]
  MAPPING = {}

  ##
  # @note Static values come from `/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h`
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
  # Tokenizer for strings. This class will take a string and break
  # it up into bit sized chunks for the string parser to parse.
  class Lexer

    attr_accessor :tokens

    def initialize string
      @chars  = string
      @tokens = []
      @index  = 0
    end

    def lex
      while @chars[@index]
        char    = @chars[@index]
        @tokens << if char == CUSTOM_ESCAPE && real_custom?
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
        when SPACE
          return [@chars[start_index...@index]]
        when nil
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

    # is it a real custom escape?
    # kind of a lie, there is one case it does not handle
    def real_custom?
      (char = @chars[@index+1]) &&
        char == char.upcase &&
        char != SPACE
    end

    SPACE         = ' '
    PLUS          = '+'
    CUSTOM_ESCAPE = "\\"
  end

  ##
  # Generate a sequence of keyboard events given tokens.
  class EventGenerator
    def initialize tokens
      @tokens = tokens
      # *4 since the output array will be at least *2 the
      # number of tokens passed in, but will often be larger
      # due to shifted/optioned characters and custom escapes
      # though a better number could be derived from
      # analyzing common input...
      @events = Array.new tokens.size*4
      @index  = 0
    end

    attr_reader :events

    def generate
      @tokens.each do |token|
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
      @events.compact!
      self
    end


    private

    def generate_custom token
      code = CUSTOM.fetch token.first[1..-1] do
        generate_dynamic token.first
        nil
      end
      return unless code
      @events[@index]   = [code,true]
      @events[@index+1] = [code,false]
      @index += 2
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

    CUSTOM_ESCAPE = "\\"
    OPTION_DOWN   = [58,true]
    OPTION_UP     = [58,false]
    SHIFT_DOWN    = [56,true]
    SHIFT_UP      = [56,false]
  end


  def events_for string
    EventGenerator.new(Lexer.new(string).lex.tokens).generate.events
  end

end

##
# @note This will only work if a run loop is runnig
#
# Register to be notified if the keyboard layout changes at runtime
NSDistributedNotificationCenter.defaultCenter.addObserver Accessibility::String,
                                                selector: 'regenerate_dynamic_mapping',
                                                    name: KTISNotifySelectedKeyboardInputSourceChanged,
                                                  object: nil

# Initialize the table
Accessibility::String.regenerate_dynamic_mapping
