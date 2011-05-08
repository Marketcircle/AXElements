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
require 'AXElements/Element'
require 'AXElements/Search'

require 'AXElements/Elements/Application'
require 'AXElements/Elements/SystemWide'

require 'AXElements/Accessibility'

module AX
  # @return [AX::SystemWide]
  SYSTEM = AX::SystemWide.instance
  # @return [AX::Application] the Mac OS X dock application
  DOCK = Application.application_with_bundle_identifier 'com.apple.dock'
end

require 'AXElements/Actions'
module Kernel
  include Accessibility::Language
end
