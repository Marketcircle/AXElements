framework 'Cocoa'

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

require 'AXElements/Version'
require 'AXElements/MacRubyExtensions'
require 'AXElements/Mouse'

require 'AXElements/Core'
require 'AXElements/Accessibility'
require 'AXElements/Search'

require 'AXElements/Element'
require 'AXElements/Elements/Application'
require 'AXElements/Elements/SystemWide'

require 'AXElements/Actions'

require 'AXElements/Constants'
require 'AXElements/Actions'
module Kernel
  include Accessibility::Lanugage
end
