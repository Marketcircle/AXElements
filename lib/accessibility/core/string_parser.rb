require 'ax_elements/key_coder'

##
# Parses strings of human readable text into a series of events meant
# to be processed by {Accessibility::Core#post:to:}.
module Accessibility::Core
  class StringParser

    ##
    # @note Static values come from `/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h`
    #
    # Map of characters to keycodes. The map is generated at boot time in
    # order to support multiple keyboard layouts.
    #
    # @return [Hash{String=>Fixnum}]
    MAPPING = KeyCodeGenerator.dynamic_mapping

    ESCAPES = {
      "\n"              => 0x24,
      "\\ESCAPE"        => 0x35,
      "\\COMMAND"       => 0x37,
      # kVK_Shift       = 0x38,
      "\\CAPS"          => 0x39,
      "\\OPTION"        => 0x3A,
      "\\CONTROL"       => 0x3B,
      # kVK_RightShift  = 0x3C,
      "\\ROPTION"       => 0x3D,
      "\\RCONTROL"      => 0x3E,
      "\\FUNCTION"      => 0x3F,
      "\\F17"           => 0x40,
      "\\VOLUP"         => 0x48,
      "\\VOLDOWN"       => 0x49,
      "\\MUTE"          => 0x4A,
      "\\F18"           => 0x4F,
      "\\F19"           => 0x50,
      "\\F20"           => 0x5A,
      "\\F5"            => 0x60,
      "\\F6"            => 0x61,
      "\\F7"            => 0x62,
      "\\F3"            => 0x63,
      "\\F8"            => 0x64,
      "\\F9"            => 0x65,
      "\\F11"           => 0x67,
      "\\F13"           => 0x69,
      "\\F16"           => 0x6A,
      "\\F14"           => 0x6B,
      "\\F10"           => 0x6D,
      "\\F12"           => 0x6F,
      "\\F15"           => 0x71,
      "\\HELP"          => 0x72,
      "\\HOME"          => 0x73,
      "\\PAGEUP"        => 0x74,
      "\\DELETE"        => 0x75,
      "\\F4"            => 0x76,
      "\\END"           => 0x77,
      "\\F2"            => 0x78,
      "\\PAGEDOWN"      => 0x79,
      "\\F1"            => 0x7A,
      "\\<-"            => 0x7B,
      "\\LEFT"          => 0x7B,
      "\\->"            => 0x7C,
      "\\RIGHT"         => 0x7C,
      "\\DOWN"          => 0x7D,
      "\\UP"            => 0x7E,
    }

    ALT = {
      '~' => '`',
      '!' => '1',
      '@' => '2',
      '#' => '3',
      '$' => '4',
      '%' => '5',
      '^' => '6',
      '&' => '7',
      '*' => '8',
      '(' => '9',
      ')' => '0',
      '{' => '[',
      '}' => ']',
      '?' => '/',
      '+' => '=',
      '|' => "\\",
      ':' => ';',
      '_' => '-',
      '"' => "'",
      '<' => ',',
      '>' => '.',
      'A' => 'a',
      'B' => 'b',
      'C' => 'c',
      'D' => 'd',
      'E' => 'e',
      'F' => 'f',
      'G' => 'g',
      'H' => 'h',
      'I' => 'i',
      'J' => 'j',
      'K' => 'k',
      'L' => 'l',
      'M' => 'm',
      'N' => 'n',
      'O' => 'o',
      'P' => 'p',
      'Q' => 'q',
      'R' => 'r',
      'S' => 's',
      'T' => 't',
      'U' => 'u',
      'V' => 'v',
      'W' => 'w',
      'X' => 'x',
      'Y' => 'y',
      'Z' => 'z'
    }

    ##
    # Parse a string into a list of keyboard events to be executed in
    # the given order.
    #
    # @param [String]
    # @return [Array<Array(Number,Boolean)>]
    def parse string
      chars  = string.split ::EMPTY_STRING
      events = []
      until chars.empty?
        char = chars.shift
        event = if ALT[char]
                  parse_alt char
                elsif char == "\\"
                  parse_custom chars
                else
                  parse_dynamic char
                end
        events.concat event
      end
      events
    end


    private

    def parse_alt char
      code  = MAPPING[ALT[char]]
      [[56,true], [code,true], [code,false], [56,false]]
    end

    def parse_custom string
      raise NotImplementedError
      # +
      #  have to go deeper
      # space
      #  done
      #
      # read letters into a new string until one of them is a space or +
      # new string is the token to look up
      # if it was space that we ended on, then do keydown and up and return
      # if it was a +, then sandwich a recursive call between key down and key up
    end

    def parse_dynamic char
      if code = MAPPING[char]
        [[code,true], [code,false]]
      else
        raise ArgumentError, "#{char} has no mapping, bail!"
      end
    end

  end
end
