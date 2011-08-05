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

##
# Container for all the accessibility objects as well as core abstraction
# layer that that interact with OS X Accessibility APIs.
module AX; end

##
# The module that contains all the things that we need for working
# with the accessibility APIs.
module Accessibility
  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log       = Logger.new $stderr
  @log.level = Logger::ERROR # @todo need to fix this
end

require 'ax_elements/version'
require 'ax_elements/macruby_extensions'
require 'ax_elements/core'
require 'ax_elements/inspector'
require 'ax_elements/accessibility'
require 'ax_elements/element'
require 'ax_elements/mouse'
