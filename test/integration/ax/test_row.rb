require 'test/integration/helper'

class TestAXRow < MiniTest::Unit::TestCase

  def table; @@table ||= app.main_window.table end
  def rows;  @@rows  ||= table.rows end
  def row;               rows.first end

  def test_child_in_column
    assert_equal row.children.second, row.child_in_column(header: 'Two')
    assert_equal row.children.first,  row.child_in_column(header: 'One')

    assert_raises Accessibility::SearchFailure do
      rows.first.child_in_column header: 'Fifty'
    end
  end

  def bench_row_in_column
    skip 'TODO'
  end

end
