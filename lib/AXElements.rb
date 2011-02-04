require   'logger'
framework 'Cocoa'

# check that the new bridge support exists
# check that the Accessibility APIs are enabled
begin
  unless AXAPIEnabled()
    NSLog('The Accessibility APIs are disabled on this machine.')
    NSLog('Please enable the Accessibility APIs from the System Preferences')
    exit 3
  end
rescue NoMethodError
  NSLog('You need to install the latest BridgeSupport preview for CoreFoundation access')
  exit 4
end


# A module for all the different accessibility roles.
# Inside the module, we should always try to work with the lower level APIs.
# The module should NEVER return something from the lower levels.
# To help with this, the module includes a few handy methods.
#
# ![Class Diagram](/docs/file/docs/images/AX.png)
module AX

  class << self

    # @return [Logger]
    attr_accessor :log

  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR

end


require 'AXElements/String_ext'
require 'AXElements/Traits'
require 'AXElements/Element'
require 'AXElements/Elements'
require 'AXElements/AX'
