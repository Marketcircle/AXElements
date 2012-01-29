require 'ax_elements/key_coder'

##
# Parses strings of human readable text into a series of events meant to
# be processed by {Accessibility::Core#post:to:}.
#
# Supports most, if not all, latin keyboard layouts, maybe some
# international layouts as well.
module Accessibility::StringParser

  ##
  # Regenerate the portion of the key mapping that is set dynamically based
  # on keyboard layout (e.g. US, Dvorak, etc.).
  #
  # This method should be called whenever the keyboard layout changes. If a run
  # loop is spinning then it will automatically be called.
  def self.regenerate_dynamic_mapping
    # KeyCodeGenerator is declared in the Objective-C extension
    MAPPING.merge! KeyCodeGenerator.dynamic_mapping
  end


  private

  ##
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
  ESCAPES = {
    "\\ESCAPE"        => 0x35,
    "\\COMMAND"       => 0x37,
    "\\SHIFT"         => 0x38,
    "\\CAPS"          => 0x39,
    "\\OPTION"        => 0x3A,
    "\\CONTROL"       => 0x3B,
    "\\RSHIFT"        => 0x3C,
    "\\ROPTION"       => 0x3D,
    "\\RCONTROL"      => 0x3E,
    "\\FUNCTION"      => 0x3F,
    "\\VOLUP"         => 0x48,
    "\\VOLDOWN"       => 0x49,
    "\\MUTE"          => 0x4A,
    "\\F17"           => 0x40,
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
    "\\KEYPAD0"       => 0x52,
    "\\KEYPAD1"       => 0x53,
    "\\KEYPAD2"       => 0x54,
    "\\KEYPAD3"       => 0x55,
    "\\KEYPAD4"       => 0x56,
    "\\KEYPAD5"       => 0x57,
    "\\KEYPAD6"       => 0x58,
    "\\KEYPAD7"       => 0x59,
    "\\KEYPAD8"       => 0x5B,
    "\\KEYPAD9"       => 0x5C,
    "\\KEYPADDecimal" => 0x41,
    "\\KEYPADMultiply"=> 0x43,
    "\\KEYPADPlus"    => 0x45,
    "\\KEYPADClear"   => 0x47,
    "\\KEYPADDivide"  => 0x4B,
    "\\KEYPADEnter"   => 0x4C,
    "\\KEYPADMinus"   => 0x4E,
    "\\KEYPADEquals"  => 0x51,
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
  # Map of aliased characters. They should map to characters in the
  # generated {MAPPING}.
  #
  # @return [Hash{String=>String}]
  ALIASES = {
    "\n"              => "\r"
  }

  SHIFT_DOWN = [[56, true]]
  SHIFT_UP   = [[56, false]]

  ##
  # Parse a string into a list of keyboard events to be executed in
  # the given order.
  #
  # The result is an array of keycode/keystate pairs.
  #
  # @param [String]
  # @return [Array<Array(Number,Boolean)>]
  def create_events_for string
    chars  = string.split ::EMPTY_STRING
    events = []
    until chars.empty?
      char = chars.shift
      new_events = if SHIFTED[char]
                     SHIFT_DOWN + create_events_for(SHIFTED[char]) + SHIFT_UP
                   elsif ALIASES[char]
                     create_events_for ALIASES[char]
                   elsif char == "\\"
                     _parse_escapes chars.unshift char
                   elsif code = MAPPING[char]
                     [[code,true], [code,false]]
                   else
                     raise ArgumentError, "#{char} has no mapping, bail!"
                   end
      events.concat new_events
    end
    events
  end

  ##
  # @todo OMG too many cases for one method
  #
  # Parse a custom escape sequence, possibly a hotkey sequence,
  # into one or more event pairs.
  #
  # @param [Array<String>]
  # @return [Array<Array(Number,Boolean)>]
  def _parse_escapes string
    sequence = ''
    while string
      case char = string.shift
      when '+'
        raise NotImplementedError, 'Hotkeys is not finished yet'
      when ' ', nil
        events = if code = ESCAPES[sequence]
                   [[code, true], [code, false]]
                 else
                   [[MAPPING["\\"], true], [MAPPING["\\"], false]]
                 end
        return events
      else
        sequence << char
      end
    end
    raise 'You tried to parse an empty string!'
  end

end

##
# @note This will only work if a run loop is runnig
#
# Register to be notified if the keyboard layout changes at runtime
NSDistributedNotificationCenter.defaultCenter.addObserver Accessibility::StringParser,
                                                selector: 'regenerate_dynamic_mapping',
                                                    name: KTISNotifySelectedKeyboardInputSourceChanged,
                                                  object: nil

# Initialize the table
Accessibility::StringParser.regenerate_dynamic_mapping
