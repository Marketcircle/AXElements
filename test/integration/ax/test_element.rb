require 'test/integration/helper'

class TestAXElement < MiniTest::Unit::TestCase

  def test_path_returns_correct_elements_in_correct_order
    list = app.window.close_button.ancestry
    assert_equal 3, list.size
    assert_equal app, list.third
    assert_equal app.window, list.second
    assert_equal app.window.close_button, list.first
  end

  def test_search_singular_returns_array
    result = app.search(:window)
    assert_kind_of AX::Window, result
  end

  def test_search_plural
    result = app.window.search(:buttons)
    assert_kind_of NSArray, result
  end

  def test_set_range
    box = app.window.text_area
    box.set :value, 'okey dokey lemon pokey'

    box.set :selected_text_range, 0..5
    assert_equal 0..5, box.selected_text_range

    box.set :selected_text_range, 1..5
    assert_equal 1..5, box.selected_text_range

    box.set :selected_text_range, 5...10
    assert_equal 5..9, box.selected_text_range

    box.set :selected_text_range, 1..-1
    assert_equal 1..21, box.selected_text_range

    box.set :selected_text_range, 4...-10
    assert_equal 4..11, box.selected_text_range

  ensure
    box.set :value, '' if box
  end

  def test_invalid
    refute app.invalid?

    app.main_window.button(title: 'Yes').perform :press
    bye = app.main_window.button(title: /Bye/)
    app.main_window.button(title: 'No').perform :press
    assert bye.invalid?
  end

  def test_dump_works_for_nested_tab_groups
    output = app.window.tab_group.inspect_subtree

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
