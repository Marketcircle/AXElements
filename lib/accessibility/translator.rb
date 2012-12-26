require 'accessibility/version'
require 'active_support/inflector'
require 'ax_elements/mri'

ActiveSupport::Inflector.inflections do |inflect|
  # Related to accessibility
  inflect.acronym('UI')
  inflect.acronym('RTF')
  inflect.acronym('URL')
end

framework 'ApplicationServices' if on_macruby?


##
# Maintain all the rules for transforming Cocoa constants into something
# a little more Rubyish and taking the Rubyish symbols and translating
# them back to Cocoa constants.
class Accessibility::Translator

  ##
  # Get the singleton instance of the {Accessibility::Translator} class.
  # This is meant to mimic the important functionality of the
  # `Singleton` mix-in.
  #
  # @return [Accessibility::Translator]
  def self.instance
    @instance ||= new
  end

  ##
  # Initialize the caches.
  def initialize
    init_unprefixes
    init_rubyisms
    init_cocoaifications
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
  # @param key [String]
  # @return [String]
  def unprefix key
    @unprefixes[key]
  end

  ##
  # Take an array of Cocoa accessibility constants and return an
  # array of shortened Ruby symbols.
  #
  # @example
  #
  #   rubyize ["AXRole", "AXTitleUIElement"] # => [:role, :title_ui_element]
  #
  # @param keys [Array<String>]
  # @return [Array<Symbol>]
  def rubyize keys
    keys = keys.map { |x| @rubyisms[x] }
    keys.flatten!
    keys
  end

  ##
  # Given a symbol, return the equivalent accessibility constant.
  #
  # @param key [#to_sym]
  # @return [String]
  def cocoaify key
    @cocoaifications[key.to_sym]
  end

  ##
  # Get the class name equivalent for a given symbol or string. This
  # is just a caching front end to the `#classify` method from the
  # ActiveSupport inflector.
  #
  # @example
  #
  #   classify 'text_field' # => "TextField"
  #   classify 'buttons'    # => "Button"
  #
  # @param klass [String]
  # @return [String]
  def classify klass
    @classifications[klass]
  end

  ##
  # Get the singularized version of the word passed in. This is just
  # a caching front end to the `#singularize` method from the
  # ActiveSupport inflector.
  #
  # @example
  #
  #   singularize 'buttons'     # => 'button'
  #   singularize 'check_boxes' # => 'check_box'
  #
  # @param klass [String]
  # @return [String]
  def singularize klass
    @singularizations[klass]
  end

  ##
  # Try to turn an arbitrary symbol into a notification constant, and
  # then get the value of the constant. If it cannot be turned into
  # a notification constant then the original string parameter will
  # be returned.
  #
  # @param name [#to_s]
  # @return [String]
  def guess_notification name
    name  = name.to_s.gsub /(?:^|_)(.)/ do $1.upcase! || $1 end
    const = "KAX#{name}Notification"
    Object.const_defined?(const) ? Object.const_get(const) : name
  end


  private

  def preloads
    {
     # basic preloads
     id:                   KAXIdentifierAttribute,
     placeholder:          KAXPlaceholderValueAttribute,
     # workarounds for known case where AX uses "Is" for a boolean attribute
     application_running:  KAXIsApplicationRunningAttribute,
     application_running?: KAXIsApplicationRunningAttribute,
    }
  end

  # @return [Hash{String=>String}]
  def init_unprefixes
    @unprefixes = Hash.new do |hash, key|
      hash[key] = key.sub /^[A-Z]*?AX|\s+/, EMPTY_STRING
    end
  end

  # @return [Hash{String=>Symbol}]
  def init_rubyisms
    @rubyisms = Hash.new do |hash, key|
      hash[key] = [ActiveSupport::Inflector.underscore(@unprefixes[key]).to_sym]
    end
    preloads.each_pair do |k,v| @rubyisms[v] << k end
  end

  # @return [Hash{Symbol=>String}]
  def init_cocoaifications
    @cocoaifications = Hash.new do |hash, key|
      str_key = key.to_s
      str_key.chomp! QUESTION_MARK
      hash[key] = "AX#{ActiveSupport::Inflector.camelize(str_key)}"
    end
    preloads.each_pair do |k, v| @cocoaifications[k] = v end
  end

  # @return [Hash{String=>String}]
  def init_classifications
    @classifications = Hash.new do |hash, key|
      hash[key] = ActiveSupport::Inflector.classify(key)
    end
  end

  # @return [Hash{String=>String}]
  def init_singularizations
    @singularizations = Hash.new do |hash, key|
      hash[key] = ActiveSupport::Inflector.singularize(key)
    end
  end

  # @private
  # @return [String]
  EMPTY_STRING = ''

  # @private
  # @return [String]
  QUESTION_MARK = '?'
end
