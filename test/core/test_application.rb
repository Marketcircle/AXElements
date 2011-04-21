class TestAXApplication < MiniTest::Unit::TestCase

  def test_is_subclass_of_element
    assert AX::Application.ancestors.include?(AX::Element)
  end

  # # @todo mocking is almost not worth it
  # def test_application_with_bundle_identifier
  #   def dup_class.AX

  #   end
  #   dup_class.application_with_bundle_identifier 'com.apple.dock'
  #   # assert mock
  # end

  def test_set_attribute_has_special_case_for_focus
    dup_class  = AX::Application.dup
    was_called = false
    dup_class.send :define_method, :set_focus do was_called = true end
    AX::DOCK.set_attribute :focused, true
    assert was_called
  end

  def test_inspect_includes_pid
    assert_match /\s@pid=/, AX::DOCK.inspect
  end

  # @todo make this test stronger
  def test_can_post_keyboard_events
    assert AX::Application.instance_methods.include?(:post_kb_string)
  end

end
