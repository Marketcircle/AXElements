class TestAXRow < MiniTest::Unit::TestCase
  include Accessibility::Core

  def app
    @@app ||= AX::Application.new REF, attrs_for(REF)
  end

  def table
    @@table ||= app.main_window.table
  end

  def rows
    @@rows ||= table.rows
  end

  def test_child_in_column
    row = rows.first
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
