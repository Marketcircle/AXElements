class TestAXSystemWide < MiniTest::Unit::TestCase

  def test_is_singleton
    assert_raises NoMethodError do
      AX::SystemWide.new
    end
    assert_includes AX::SystemWide.instance_methods, :instance
  end

end


class TestAXSystemWideTypeString < MiniTest::Unit::TestCase

  def test_makes_appropriate_callback
    class << AX
      alias_method :old_keyboard_action, :keyboard_action
      def keyboard_action element, string
        true if string == 'test' && element == AXUIElementCreateSystemWide()
      end
    end
    assert AX::SYSTEM.type_string('test')
  ensure
    class << AX
      alias_method :keyboard_action, :old_keyboard_action
    end
  end

end


class TestAXSystemWideSearch < MiniTest::Unit::TestCase

  def test_not_allowed
    assert_raises NoMethodError do
      AX::SYSTEM.search
    end
  end

end


class TestAXSystemWideOnNotification < MiniTest::Unit::TestCase

  def test_not_allowed
    assert_raises NoMethodError do
      AX::SYSTEM.search
    end
  end

end
