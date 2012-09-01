require 'test/helper'
require 'accessibility/factory'
require 'ax/application'

class TestAccessibilityElementFactory < MiniTest::Unit::TestCase

  def app;    @@app    ||= Accessibility::Element.new REF       end
  def window; @@window ||= app.attribute KAXMainWindowAttribute end

  def scroll_area
    @@area ||= window.children.find { |x|
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
    assert_equal app, app.to_ruby.instance_variable_get(:@ref)

    o = web_area.to_ruby
    assert_instance_of AX::WebArea, o

    # intentionally done twice to see if the created class is
    # used again; this guarantees that the class can be created
    # properly and then used again when needed
    2.times do
      o = window.to_ruby
      assert_instance_of AX::StandardWindow, o, 'class_for2 failed'
      o = close_button.to_ruby
      assert_instance_of AX::CloseButton, o, 'class_for2 failed'
    end

    2.times do
      o = app.to_ruby
      assert_instance_of AX::Application, o, 'class_for failed'
      o = scroll_area.to_ruby
      assert_instance_of AX::ScrollArea, o, 'class_for failed'
    end
  end

  # @todo bencmark Element#to_ruby

end
