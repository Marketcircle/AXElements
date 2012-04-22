require 'test/integration/helper'

class TestAccessibilityDebug < MiniTest::Unit::TestCase

  def app
    @app ||= AX::Application.new PID
  end

  def test_dump_works_for_nested_tab_groups
    element = app.window.tab_group
    output  = Accessibility::Debug.subtree_for element

    expected = [
                ['AX::TabGroup',    0],
                ['AX::RadioButton', 1], ['AX::RadioButton', 1], ['AX::TabGroup', 1],
                ['AX::RadioButton', 2], ['AX::RadioButton', 2], ['AX::TabGroup', 2],
                ['AX::RadioButton', 3], ['AX::RadioButton', 3], ['AX::TabGroup', 3],
                ['AX::RadioButton', 4], ['AX::RadioButton', 4],
                ['AX::Group',       4],
                ['AX::TextField',   5], ['AX::StaticText',  6],
                ['AX::TextField' ,  5], ['AX::StaticText',  6]
               ]

    refute_empty output
    output = output.split("\n")

    until output.empty?
      line           = output.shift
      klass, indents = expected.shift
      assert_equal indents, line.match(/^\t*/).to_a.first.length, line
      line.strip!
      assert_match /^\#<#{klass}/, line
    end
  end

end
