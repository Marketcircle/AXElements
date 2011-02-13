module AX
module Traits

  # In cases where you need to simulate keyboard input, such as entering
  # passwords or triggering hotkeys, you will need to use this method.
  #
  # See the documentation page
  # [KeyboardEvents](../../file/KeyboardEvents.markdown)
  # on how to encode strings and other details on using methods from
  # this module.
  module Typing

    # @todo a small parser to generate the actual sequence of key presses to
    #  simulate. Most likely just going to extend built in string escape sequences.
    # Key codes are independant of the layout in the sense that they are
    # absolute key positions on the keyboard and that different layouts will
    # fuck things up differently.
    #
    # For testing we are going to have to standardize on one layout.
    #
    # A capital letter requires pressing caps lock or holding down the shift key.
    # You need to set keydown for the key and then !keydown or else it will act
    # like a key combination.
    # @param [String] string the string you want typed on the screen
    # @return [Boolean] always returns true
    def post_kb_event string
      string.each_char { |char|
        code = KEYCODE_MAP[char]
        AXUIElementPostKeyboardEvent(@ref, 0, code, true)
        AXUIElementPostKeyboardEvent(@ref, 0, code, false)
      }
      true
    end

    KEYCODE_MAP = {
      'a' => 0,
      'b' => 11,
      'c' => 8,
      'd' => 2,
      'e' => 14,
      'f' => 3,
      'g' => 5,
      'h' => 4,
      'i' => 34,
      'j' => 38,
      'k' => 40,
      'l' => 37,
      'm' => 46,
      'n' => 45,
      'o' => 31,
      'p' => 35,
      'q' => 12,
      'r' => 15,
      's' => 1,
      't' => 17,
      'u' => 32,
      'v' => 9,
      'w' => 13,
      'x' => 7,
      'y' => 16,
      'z' => 6,
      '1' => 18,
      '2' => 19,
      '3' => 20,
      '4' => 21,
      '5' => 23,
      '6' => 22,
      '7' => 26,
      '8' => 28,
      '9' => 25,
      '0' => 29,
      "\t"=> 48,
      ' ' => 49,
      "\e"=> 53
    }
  end

end
end
