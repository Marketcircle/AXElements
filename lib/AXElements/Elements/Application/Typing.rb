module AX
class Application

  ##
  # @todo look at CGEventKeyboardSetUnicodeString for posting events
  #       without needing the keycodes
  # @todo look at UCKeyTranslate for working with different keyboard
  #       layouts
  # @todo a small parser to generate the actual sequence of key presses to
  #       simulate. Most likely just going to extend built in string escape
  #       sequences if possible
  # @note This method only handles lower case letters, spaces, tabs, and
  #       the escape key right now.
  #
  # In cases where you need to simulate keyboard input, such as entering
  # passwords or triggering hotkeys, you will need to use this method.
  #
  # See the documentation page
  # [KeyboardEvents](../../file/KeyboardEvents.markdown)
  # on how to encode strings, as well as other details on using methods
  # from this module.
  #
  # Key codes are independant of the layout in the sense that they are
  # absolute key positions on the keyboard and that different layouts will
  # fuck things up differently.
  #
  # For testing we are going to have to standardize on one layout or find
  # a way to map across different layouts.
  #
  # @param [String] string the string you want typed on the screen
  # @return [Boolean] true unless something goes horribly wrong
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
