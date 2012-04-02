require 'test/helper'
require 'accessibility/factory'
require 'ax/element'
require 'ax/application'

# Just pretend that you didn't see this
class AX::Element
  attr_reader :ref
end

class TestAccessibilityFactory < MiniTest::Unit::TestCase
  include Accessibility::Factory

  def window
    REF.children.find { |x| x.role == KAXWindowRole }
  end

  def scroll_area
    window.children.find { |x|
      x.attributes.include?(KAXDescriptionAttribute) &&
        x.attribute(KAXDescriptionAttribute) == 'Test Web Area'
    }
  end

  def web_area
    scroll_area.children.find { |x| x.role == 'AXWebArea' }
  end

  def close_button
    window.children.find { |x|
      x.attributes.include?(KAXSubroleAttribute) &&
        x.attribute(KAXSubroleAttribute) == KAXCloseButtonSubrole
    }
  end

  def test_processing_element_refs
    assert_equal REF, process(REF).ref

    o = process(web_area)
    assert_instance_of AX::WebArea, o

    # intentionally done a second time to see if the
    # created class is used again; this guarantees
    # that the class can be created properly and then
    # used again when needed
    2.times do
      o = process window
      assert_instance_of AX::StandardWindow, o
      o = process close_button
      assert_instance_of AX::CloseButton, o
    end

    2.times do
      o = process REF
      assert_instance_of AX::Application, o
      o = process scroll_area
      assert_instance_of AX::ScrollArea, o
    end
  end

  def test_processing_arrays
    assert_equal [],  process_array([])
    assert_equal [1], process_array([1])

    expected = [AX::Application.new(REF)]
    assert_equal expected, process_array([REF])
  end

  def test_processing_arbitrary_objects
    assert_equal 'test', process('test')
    assert_equal 42,     process(42)

    now = Time.now
    assert_equal now, process(now)

    string = NSAttributedString.alloc.initWithString 'hi'
    assert_equal string, process(string)
  end

  def test_processing_nil
    assert_nil process(nil)
  end

  def bench_process
    skip 'This is important when we get to optimizing'
  end

end
