class TestElementsRowChildInColumn < TestAX

  # these tests depend on Search already working

  APP = AX::Application.new REF

  def table
    @@table ||= APP.main_window.table
  end

  def rows
    @@rows ||= table.rows
  end

  def test_returns_correct_column
    row = rows.first
    assert_equal row.children.second, row.child_in_column(header: 'Two')
    assert_equal row.children.first,  row.child_in_column(header: 'One')
  end

  def test_raises_seach_failure_if_nothing_found
    assert_raises AX::Element::SearchFailure do
      rows.first.child_in_column(header: 'Fifty')
    end
  end

end
