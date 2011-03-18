require 'AXElements/Version'

# @todo switch to ApplicationServices when the NS constants go away
framework 'Cocoa'

# @todo embed the new bridge support?
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

require 'AXElements/CoreExtensions'
require 'AXElements/Traits'
require 'AXElements/Element'
require 'AXElements/Elements'
require 'AXElements/AX'
