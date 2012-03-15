require 'singleton'
require 'ax_elements/vendor/inflector'

##
# Maintain all the rules for transforming Cocoa constants into something
# a little more Rubyish.
class Accessibility::Translator
  include Singleton

  ##
  # Initialize the caches.
  def initialize
    init_unprefixes
    init_normalizations
    init_rubyisms
    init_classifications
    init_singularizations
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

  ##
  # Given a symbol, return the equivalent accessibility constant.
  #
  # @param [#to_sym]
  # @param [Array<String>]
  # @return [String]
  def lookup key, with: values
    @values = values
    @rubyisms[key.to_sym]
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

  ##
  # Get the class name equivalent for a given symbol or string. This
  # is just a caching front end to the `#classify` method from the
  # ActiveSupport inflector.
  #
  # @example
  #
  #   classify :text_field  # => "TextField"
  #   classify :buttons     # => "Button"
  #
  # @param [#to_s]
  # @return [String]
  def classify klass
    @classifications[klass.to_s]
  end

  ##
  # Get the singularized version of the word passed in. This is just
  # a caching front end to the `#singularize` method from the
  # ActiveSupport inflector.
  #
  # @example
  #
  #   singularize :buttons      # => 'button'
  #   singularize :check_boxes  # => 'check_box'
  #
  # @param [#to_s]
  # @return [String]
  def singularize klass
    @singularizations[klass.to_s]
  end


  private

  ##
  # @private
  #
  # Performance hack.
  #
  # @return [String]
  QUESTION_MARK = '?'

  # @return [Hash{String=>String}]
  def init_unprefixes
    @unprefixes = Hash.new do |hash, key|
      hash[key] = key.sub /^[A-Z]*?AX(?:Is)?|\s+/, ::EMPTY_STRING
    end
  end

  # @return [Hash{String=>Symbol}]
  def init_normalizations
    @normalizations = Hash.new do |hash, key|
      hash[key] = @unprefixes[key].underscore.to_sym
    end
  end

  # @return [Hash{Symbol=>String}]
  def init_rubyisms
    @rubyisms = Hash.new do |hash, key|
      @values.each do |v| hash[@normalizations[v]] = v end
      hash.fetch(key) do |k|
        chomped_key = k.chomp(QUESTION_MARK).to_sym
        chomped_val = hash.fetch(chomped_key, nil)
        hash[key]   = chomped_val if chomped_val
      end
    end
    # preload the table
    @rubyisms[:id]          = KAXIdentifierAttribute
    @rubyisms[:placeholder] = KAXPlaceholderValueAttribute
  end

  # @return [Hash{String=>String}]
  def init_classifications
    @classifications = Hash.new do |hash, key|
      hash[key] = Accessibility::Inflector.classify(key)
    end
  end

  # @return [Hash{String=>String}]
  def init_singularizations
    @singularizations = Hash.new do |hash, key|
      hash[key] = Accessibility::Inflector.singularize(key)
    end
  end

end
