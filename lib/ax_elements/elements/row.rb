##
# UI Element for the row in a table, outline, etc.
class AX::Row < AX::Element

  ##
  # @todo Can this be more efficient? It wraps the columns twice,
  #       which is expensive if there are many columns. Needs to be
  #       done in such that we preserve search semantics for the
  #       filters.
  #
  # Retrieve the child in a row that corresponds to a specific column.
  # You must pass filters here in the same way that you would for a
  # search.
  #
  # @example
  #
  #   table.row[5].child_in_column(header: 'Price')
  #
  # @param [Hash]
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
