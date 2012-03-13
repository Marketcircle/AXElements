require 'ax/element'
require 'accessibility/qualifier'

##
# UI Element for the row in a table, outline, etc.
class AX::Row < AX::Element

  ##
  # Retrieve the child in a row that corresponds to a specific column.
  # You must pass filters here in the same way that you would for a
  # search.
  #
  # This is useful for tables where it is difficult to identify which
  # row item is the one you want based on the row items themselves.
  # Often times the columns in the table will have identifying attributes,
  # such as a header, and so you can use this method to figure out what
  # column your row item is in and then the method will return the row
  # item you wanted.
  #
  # @example
  #
  #   rows  = table.rows
  #   total = rows.inject(0) { |sum, row|
  #     sum += row.child_in_column(header: 'Price').value.to_i
  #   }
  #   puts "The average price is $ #{total / rows.size}"
  #
  # @param [Hash]
  # @return [AX::Element]
  def child_in_column filters
    block     = block_given? ? Proc.new : nil
    qualifier = Accessibility::Qualifier.new(:Column, filters, &block)
    column    = self.parent.columns.index { |x| qualifier.qualifies? x }
    return self.children.at(column) if column
    raise Accessibility::SearchFailure.new(self.parent, 'column', filters)
  end

end
