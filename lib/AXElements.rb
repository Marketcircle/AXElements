require   'logger'
framework 'Cocoa'

begin
  # check that the new bridge support exists
  # check that the Accessibility APIs are enabled
  unless AXAPIEnabled()
    NSLog('The Accessibility APIs are disabled on this machine.')
    NSLog('Please enable the Accessibility APIs from the System Preferences')
    exit 3
  end
rescue NoMethodError
  NSLog('You need to install the latest BridgeSupport preview for CoreFoundation access')
  exit 4
end

require   'AXElements/monkey'
require   'AXElements/Traits'
require   'AXElements/Element'
require   'AXElements/Elements'
require   'AXElements/AX'
module AX

  class << self

    # @return [Logger]
    attr_accessor :log

  end

  @log = Logger.new $stderr
  @log.level = Logger::INFO

end
