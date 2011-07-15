framework 'Cocoa'
require   'logger'

# check that the Accessibility APIs are enabled and are available to MacRuby
begin
  unless AXAPIEnabled()
    raise RuntimeError, <<-EOS
Universal Access is disabled on this machine. Please enable it in the System Preferences.
    EOS
  end
rescue NoMethodError
  raise NotImplementedError, <<-EOS
You need to install the latest BridgeSupport preview for AXElements to work.
  EOS
end

require 'active_support/inflector'
require 'ax_elements/macruby_extensions'
require 'ax_elements/mouse'

##
# Container for all the accessibility objects as well as the set of
# stateless singleton methods that interact with OS X Accessibility
# APIs.
module AX; end

##
# The module that contains all the things that we need for working
# with the accessibility APIs.
module Accessibility
  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR
end

require 'ax_elements/version'
require 'ax_elements/core'
require 'ax_elements/accessibility'
require 'ax_elements/element'
