require 'test/helper'
require 'accessibility/factory'
require 'ax/application'

class TestAccessibilityElementFactory < MiniTest::Unit::TestCase

  def window
    @@window ||= REF.to_ruby.children.find { |x| x.role == KAXWindowRole }
  end

  def scroll_area
    @@scroll_area ||= window.children.find { |x|
      x.attributes.include?(:description) &&
        x.description == 'Test Web Area'
    }
  end

  def web_area
    @@web_area ||= scroll_area.children.find { |x| x.role == 'AXWebArea' }
  end

  def close_button
    @@close_button ||= window.children.find { |x|
      x.attributes.include?(:subrole) &&
        x.attribute(:subrole) == KAXCloseButtonSubrole
    }
  end

  def test_processing_element_refs
    assert_equal REF, REF.to_ruby.instance_variable_get(:@ref)

    o = web_area
    assert_instance_of AX::WebArea, o

    # intentionally done twice to see if the created class is
    # used again; this guarantees that the class can be created
    # properly and then used again when needed
    2.times do
      o = window
      assert_instance_of AX::StandardWindow, o, 'class_for2 failed'
      o = close_button
      assert_instance_of AX::CloseButton, o, 'class_for2 failed'
    end

    2.times do
      o = REF.to_ruby
      assert_instance_of AX::Application, o, 'class_for failed'
      o = scroll_area
      assert_instance_of AX::ScrollArea, o, 'class_for failed'
    end
  end

  # @todo bencmark Element#to_ruby

end
