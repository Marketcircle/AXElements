# Functional and system tests for AXElements

class TestAccessibilityDSL < MiniTest::Unit::TestCase

  class DSL
    include Accessibility::DSL
  end

  def dsl
    @dsl ||= DSL.new
  end

  def app
    @@app ||= Accessibility.application_with_pid PID
  end

  def text_area
    @@text_area ||= app.main_window.text_area
  end

  def test_type
    def try string, expected = nil
      expected = string unless expected
      text_area.set :focused, to: true
      dsl.type string
      assert_equal expected, text_area.value
    ensure # reset for next test
      dsl.type "\\COMMAND+a \b"
    end

    try "A proper sentence, with punctuation and the number 9. LOL!\tA 'quoted' string--then some @#*$ cursing."
    try "The cake is a lie!\b\b\b\bgift!", 'The cake is a gift!'
    try ", world!\\CONTROL+a Hello", 'Hello, world!'
    try "Hai.\\<- \\<- \b", "Hi."
    try "First line.\nSecond line."
  end

end
