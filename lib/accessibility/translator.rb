require 'singleton'


class Accessibility::Translator
  include Singleton

  def initialize
    @prefixes = Hash.new do |h,k|
      h[k] = k.sub /^[A-Z]*?AX(?:Is)?|\s+/, ::EMPTY_STRING
    end
  end

  ##
  # @note In the case of a predicate name, this will strip the 'Is'
  #       part of the name if it is present
  #
  # Takes an accessibility constant and returns a new string with the
  # namespace prefix removed.
  #
  # @example
  #
  #   ['AXTitle']                    # => 'Title'
  #   ['AXIsApplicationEnabled']     # => 'ApplicationEnabled'
  #   ['MCAXEnabled']                # => 'Enabled'
  #   [KAXWindowCreatedNotification] # => 'WindowCreated'
  #   [NSAccessibilityButtonRole]    # => 'Button'
  #
  # @param [String] const
  # @return [String]
  def [] key
    @prefixes[key]
  end

end
