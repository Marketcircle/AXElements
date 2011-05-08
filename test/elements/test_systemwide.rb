class TestAXSystemWide < MiniTest::Unit::TestCase

  def test_makes_appropriate_callback
    class << AX
      alias_method :old_keyboard_action, :keyboard_action
      def keyboard_action element, string
        true if string == 'test'
      end
    end
    assert AX::SYSTEM.type_string('test')
  ensure
    class << AX
      alias_method :keyboard_action, :old_keyboard_action
    end
  end

end
