framework 'Cocoa'
require   'logger'

# check that the new bridge support exists
# check that the Accessibility APIs are enabled
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
# Helper methods and other metadata
module Accessibility
  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR
end

##
# Container for all the accessibility objects as well as the set of
# stateless singleton methods that interact with OS X Accessibility
# APIs.
module AX
end

require 'AXElements/Version'
require 'AXElements/MacRubyExtensions'
require 'AXElements/Mouse'

require 'AXElements/Core'
require 'AXElements/Element'
require 'AXElements/Search'

require 'AXElements/Elements/Application'
require 'AXElements/Elements/SystemWide'

require 'AXElements/Accessibility'
require 'AXElements/Language'

module AX
  # @return [AX::SystemWide]
  SYSTEM = AX::SystemWide.instance

  # @return [AX::Application] the Mac OS X dock application
  DOCK = Application.application_with_bundle_identifier 'com.apple.dock'
end

# Mix the language methods in to the TopLevel
include Accessibility::Language
