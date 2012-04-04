require 'test/integration/helper'

class TestNSArrayCompat < MiniTest::Unit::TestCase

  def app
    @@app ||= AX::Application.new PID
  end

  def test_raises_for_non_elements
    assert_raises NoMethodError do
      [1].rows
    end

    assert_raises NoMethodError do
      [app,1].titles
    end
  end

  def test_normally_pluralized_method_names_work
    table  = app.main_window.table
    result = [table,table].rows
    assert_equal result.first, result.last
  end

  def test_artificially_pluralized_method_names_work
    assert_equal [app.title], [app].titles
  end

  def test_predicate_methods_work
    assert_equal [true],  [app].focused?
  end

  def test_handles_searching_an_array
    assert_equal [app].windows, [app.windows]
  end

  def test_raises_if_element_does_not_respond
    assert_raises NoMethodError do
      [app.main_window.close_button].windoze
    end
  end

end
