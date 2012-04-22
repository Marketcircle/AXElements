require 'test/runner'
require 'accessibility/highlighter'

class TestHighlighter < MiniTest::Unit::TestCase

  def bounds
    CGRectMake(100, 100, 100, 100)
  end

  def test_highlight_returns_created_window
    w = Accessibility::Highlighter.new bounds
    assert_kind_of NSWindow, w
    assert_respond_to w, :stop
  ensure
    w.close if w
  end

  def test_highlight_can_take_a_timeout
    w = Accessibility::Highlighter.new bounds, timeout: 0.1
    assert w.visible?
    sleep 0.15
    refute w.visible? # Not exactly the assertion I want, but close enough
  ensure
    w.close if w
  end

  def test_highlight_can_have_custom_colour
    w = Accessibility::Highlighter.new bounds, color: NSColor.cyanColor
    assert w.backgroundColor == NSColor.cyanColor
    w.close

    # test both spellings of colour
    w = Accessibility::Highlighter.new bounds, colour: NSColor.purpleColor
    assert w.backgroundColor == NSColor.purpleColor
  end

  def test_highlight_highlights_correct_rect
    w = Accessibility::Highlighter.new bounds
    assert_equal w.frame, bounds.flip!
  end

end

class TestCGRectExtensions < MiniTest::Unit::TestCase

  def test_flipping
    size = NSScreen.mainScreen.frame.size
    assert_equal CGRectMake(0,       size.height, 0,     0), CGRectZero.dup.flip!
    assert_equal CGRectMake(100, size.height-200, 100, 100), CGRectMake(100,100,100,100).flip!
  end

  def test_flipping_twice_returns_to_original
    assert_equal CGRectZero.dup, CGRectZero.dup.flip!.flip!
  end

end
