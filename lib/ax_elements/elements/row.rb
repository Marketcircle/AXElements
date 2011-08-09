##
# UI Element for the row in a table.
class AX::Row < AX::Element

  ##
  # @todo Make this more efficient, it needs to wrap the columns twice,
  #       which is expensive if there are many columns. A possible
  #       solution might be to add #index to Accessibility::Search so
  #       that we do not need to worry about actual columns here and
  #       can directly get the index at search time. The problem with
  #       that solution is that it assumes a flat array.
  #
  # Retrieve the child in a row that corresponds to a specific column.
  #
  # @param [Hash] filters
  # @return [AX::Element]
  def child_in_column filters
    table   = self.parent
    column  = table.column(filters)
    columns = table.columns
    index   = columns.index { |x| x == column }
    return self.children.at(index) if index
    raise AX::Element::SearchFailure.new(self.parent, 'column', filters)
  end

end
