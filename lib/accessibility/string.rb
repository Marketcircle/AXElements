# -*- coding: utf-8 -*-

require   'accessibility/version'
require   'accessibility/key_coder'
framework 'ApplicationServices' if defined? MACRUBY_VERSION

##
# Parses strings of human readable text into a series of events meant to
# be processed by {Accessibility::Core#post:to:} or {KeyCoder.post_event}.
#
# Supports most, if not all, latin keyboard layouts, maybe some
# international layouts as well.
module Accessibility::String

  ##
  # Generate keyboard events for the given string. Strings should be in a
  # human readable with a few exceptions. Command key (e.g. control, option,
  # command) should be written in string as they appear in
  # {Accessibility::String::EventGenerator::CUSTOM}.
  #
  # For more details on event generation, read the
  # {file:docs/KeyboardEvents.markdown Keyboard Events} documentation.
  #
  # @param [String]
  # @return [Array<Array(Fixnum,Boolean)>]
  def keyboard_events_for string
    EventGenerator.new(Lexer.new(string).lex).generate
  end

  ##
  # Tokenizer for strings. This class will take a string and break
  # it up into chunks for the event generator. The structure generated
  # here is an array that contains strings and recursively other arrays
  # of strings and arrays of strings.
  #
  # @example
  #
  #   Lexer.new("Hai").lex          # => ['H','a','i']
  #   Lexer.new("\\CAPSLOCK").lex   # => [["\\CAPSLOCK"]]
  #   Lexer.new("\\COMMAND+a").lex  # => [["\\COMMAND", ['a']]]
  #   Lexer.new("One\nTwo").lex     # => ['O','n','e',"\n",'T','w','o']
  #
  class Lexer

    ##
    # Once a string is lexed, this contains the tokenized structure.
    #
    # @return [Array<String,Array<String,...>]
    attr_accessor :tokens

    # @param [#to_s]
    def initialize string
      @chars  = string.to_s
      @tokens = []
    end

    ##
    # Tokenize the string that the lexer was initialized with and
    # return the sequence of tokens that were lexed.
    #
    # @return [Array<String,Array<String,...>]
    def lex
      length = @chars.length
      @index = 0
      while @index < length
        @tokens << if custom?
                     lex_custom
                   else
                     lex_char
                   end
        @index += 1
      end
      @tokens
    end


    private

    ##
    # Is it a real custom escape? Kind of a lie, there is one
    # case it does not handle--they get handled in the generator,
    # but maybe they should be handled here?
    # - An upper case letter or symbol following `"\\"` that is
    #   not mapped
    def custom?
      @chars[@index] == CUSTOM_ESCAPE &&
        (next_char = @chars[@index+1]) &&
         next_char == next_char.upcase &&
         next_char != SPACE
    end

    # @return [Array]
    def lex_custom
      start = @index
      loop do
        char = @chars[@index]
        if char == PLUS
          if @chars[@index-1] == CUSTOM_ESCAPE
            @index += 1
            return custom_subseq start
          else
            tokens  = custom_subseq start
            @index += 1
            return tokens << lex_custom
          end
        elsif char == SPACE
          return custom_subseq start
        elsif char == nil
          raise ArgumentError, "Bad escape sequence" if start == @index
          return custom_subseq start
        else
          @index += 1
        end
      end
    end

    # @return [Array]
    def custom_subseq start
      [@chars[start...@index]]
    end

    # @return [String]
    def lex_char
      @chars[@index]
    end

    # @private
    SPACE         = " "
    # @private
    PLUS          = "+"
    # @private
    CUSTOM_ESCAPE = "\\"
  end


  ##
  # @todo Add a method to generate just keydown or just keyup events.
  #       Requires separating code lookup from event creation.
  #
  # Generate a sequence of keyboard events given a sequence of tokens.
  # The token format is defined by the {Lexer} class output; it is best
  # to use that class to generate the tokens.
  #
  # @example
  #
  #   # Upper case 'A'
  #   EventGenerator.new(["A"]).generate  # => [[56,true],[70,true],[70,false],[56,false]]
  #
  #   # Press the caps lock button, turn it on
  #   EventGenerator.new([["\\CAPS"]]).generate # => [[0x39,true],[0x39,false]]
  #
  #   # Hotkey, press and hold command key and then 'a', then release both
  #   EventGenerator.new([["\\CMD",["a"]]]).generate # => [[55,true],[70,true],[70,false],[55,false]]
  #
  #   # Press the return/enter key
  #   EventGenerator.new(["\n"]).generate # => [[10,true],[10,false]]
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
      # KeyCoder is declared in the Objective-C extension
      MAPPING.merge! KeyCoder.dynamic_mapping
      # Also add an alias to the mapping
      MAPPING["\n"] = MAPPING["\r"]
    end

    ##
    # Dynamic mapping of characters to keycodes. The map is generated at
    # startup time in order to support multiple keyboard layouts.
    #
    # @return [Hash{String=>Fixnum}]
    MAPPING = {}

    # Initialize the table
    regenerate_dynamic_mapping

    ##
    # @note These mappings are all static and come from `/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h`
    #
    # Map of custom escape sequences to their hardcoded keycode value.
    #
    # @return [Hash{String=>Fixnum}]
    CUSTOM = {
      "\\ESCAPE"        => 0x35,
      "\\ESC"           => 0x35,
      "\\COMMAND"       => 0x37,
      "\\CMD"           => 0x37,
      "\\SHIFT"         => 0x38,
      "\\LSHIFT"        => 0x38,
      "\\CAPS"          => 0x39,
      "\\CAPSLOCK"      => 0x39,
      "\\OPTION"        => 0x3A,
      "\\OPT"           => 0x3A,
      "\\ALT"           => 0x3A,
      "\\CONTROL"       => 0x3B,
      "\\CTRL"          => 0x3B,
      "\\RSHIFT"        => 0x3C,
      "\\ROPTION"       => 0x3D,
      "\\ROPT"          => 0x3D,
      "\\RALT"          => 0x3D,
      "\\RCONTROL"      => 0x3E,
      "\\RCTRL"         => 0x3E,
      "\\FUNCTION"      => 0x3F,
      "\\FN"            => 0x3F,
      "\\VOLUMEUP"      => 0x48,
      "\\VOLUP"         => 0x48,
      "\\VOLUMEDOWN"    => 0x49,
      "\\VOLDOWN"       => 0x49,
      "\\MUTE"          => 0x4A,
      "\\F1"            => 0x7A,
      "\\F2"            => 0x78,
      "\\F3"            => 0x63,
      "\\F4"            => 0x76,
      "\\F5"            => 0x60,
      "\\F6"            => 0x61,
      "\\F7"            => 0x62,
      "\\F8"            => 0x64,
      "\\F9"            => 0x65,
      "\\F10"           => 0x6D,
      "\\F11"           => 0x67,
      "\\F12"           => 0x6F,
      "\\F13"           => 0x69,
      "\\F14"           => 0x6B,
      "\\F15"           => 0x71,
      "\\F16"           => 0x6A,
      "\\F17"           => 0x40,
      "\\F18"           => 0x4F,
      "\\F19"           => 0x50,
      "\\F20"           => 0x5A,
      "\\HELP"          => 0x72,
      "\\HOME"          => 0x73,
      "\\END"           => 0x77,
      "\\PAGEUP"        => 0x74,
      "\\PAGEDOWN"      => 0x79,
      "\\DELETE"        => 0x75,
      "\\LEFT"          => 0x7B,
      "\\<-"            => 0x7B,
      "\\RIGHT"         => 0x7C,
      "\\->"            => 0x7C,
      "\\DOWN"          => 0x7D,
      "\\UP"            => 0x7E,
      "\\0"             => 0x52,
      "\\1"             => 0x53,
      "\\2"             => 0x54,
      "\\3"             => 0x55,
      "\\4"             => 0x56,
      "\\5"             => 0x57,
      "\\6"             => 0x58,
      "\\7"             => 0x59,
      "\\8"             => 0x5B,
      "\\9"             => 0x5C,
      "\\Decimal"       => 0x41,
      "\\."             => 0x41,
      "\\Plus"          => 0x45,
      "\\+"             => 0x45,
      "\\Multiply"      => 0x43,
      "\\*"             => 0x43,
      "\\Minus"         => 0x4E,
      "\\-"             => 0x4E,
      "\\Divide"        => 0x4B,
      "\\/"             => 0x4B,
      "\\Equals"        => 0x51,
      "\\="             => 0x51,
      "\\Enter"         => 0x4C,
      "\\Clear"         => 0x47,
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
      # *3 since the output array will be at least *2 the
      # number of tokens passed in, but will often be larger
      # due to shifted/optioned characters and custom escapes;
      # though a better number could be derived from
      # analyzing common input...
      @events = Array.new tokens.size*3
    end

    ##
    # Generate the events for the tokens the event generator
    # was initialized with. Returns the generated events.
    #
    # @return [Array<Array(Fixnum,Boolean)>]
    def generate
      @index = 0
      gen_all @tokens
      @events.compact!
      @events
    end


    private

    def add event
      @events[@index] = event
      @index += 1
    end

    def gen_all tokens
      tokens.each do |token|
        if token.kind_of? Array
          gen_nested token.first, token[1..-1]
        else
          gen_single token
        end
      end
    end

    def gen_nested head, tail
      if code = CUSTOM[head] || SHIFTED[head] || OPTIONED[head] || MAPPING[head]
        add [code, true]
        gen_all tail
        add [code, false]
      else # handling a special case
        gen_all head.split(EMPTY_STRING)
      end
    end

    def gen_single token
      ((code =  MAPPING[token]) &&  gen_dynamic(code)) ||
      ((code =  SHIFTED[token]) &&  gen_shifted(code)) ||
      ((code = OPTIONED[token]) && gen_optioned(code)) ||
      raise(ArgumentError, "#{token.inspect} has no mapping, bail!")
    end

    def gen_shifted code
      add SHIFT_DOWN
      gen_dynamic MAPPING[code]
      add SHIFT_UP
    end

    def gen_optioned code
      add OPTION_DOWN
      gen_dynamic MAPPING[code]
      add OPTION_UP
    end

    def gen_dynamic code
      add [code,  true]
      add [code, false]
    end

    # @private
    EMPTY_STRING = ''
    # @private
    OPTION_DOWN  = [58, true]
    # @private
    OPTION_UP    = [58, false]
    # @private
    SHIFT_DOWN   = [56, true]
    # @private
    SHIFT_UP     = [56, false]
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
