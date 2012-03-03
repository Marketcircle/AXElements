require 'singleton'

##
# Maintain all the rules for transforming Cocoa constants into something
# a little more Rubyish.
class Accessibility::Translator
  include Singleton

  ##
  # Initialize the caches.
  def initialize
    @unprefixes     = Hash.new do |hash, key|
      hash[key] = key.sub /^[A-Z]*?AX(?:Is)?|\s+/, ::EMPTY_STRING
    end
    @normalizations = Hash.new do |hash, key|
      hash[key] =  @unprefixes[key].underscore.to_sym
    end
    @rubyisms       = Hash.new do |hash, key|
      @values.each { |value| hash[@normalizations[value]] = value }
      if hash.has_key? key
        hash[key]
      else
        chomped_key = key.chomp(QUESTION_MARK).to_sym
        if hash.has_key? chomped_key
          hash[chomped_key]
        end
      end
    end
    # preload the table
    @rubyisms['id']          = KAXIdentifierAttribute
    @rubyisms['placeholder'] = KAXPlaceholderValueAttribute
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
  #   unprefix 'AXTitle'                    # => 'Title'
  #   unprefix 'AXIsApplicationEnabled'     # => 'ApplicationEnabled'
  #   unprefix 'MCAXEnabled'                # => 'Enabled'
  #   unprefix KAXWindowCreatedNotification # => 'WindowCreated'
  #   unprefix NSAccessibilityButtonRole    # => 'Button'
  #
  # @param [String]
  # @return [String]
  def unprefix key
    @unprefixes[key]
  end

  # @return [String]
  def lookup key, with: values
    @values = values
    @rubyisms[key.to_s]
  end

  # @return [Array<Symbol>]
  def rubyize keys
    keys.map { |x| @normalizations[x] }
  end

  ##
  # Try to turn an arbitrary symbol into a notification constant, and
  # then get the value of the constant.
  #
  # @param [#to_s]
  # @return [String]
  def guess_notification_for name
    name  = name.to_s
    const = "KAX#{name.camelize}Notification"
    Object.const_defined?(const) ? Object.const_get(const) : name
  end


  private

  ##
  # @private
  #
  # Performance hack.
  #
  # @return [String]
  QUESTION_MARK = '?'

end
