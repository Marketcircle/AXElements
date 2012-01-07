framework 'Cocoa'

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


unless Object.const_defined? :KAXIdentifierAttribute
  ##
  # Added for backwards compatability with Snow Leopard.
  #
  # @return [String]
  KAXIdentifierAttribute = 'AXIdentifier'.freeze
end


require 'ax_elements/macruby_extensions'
require 'ax_elements/version'
require 'ax_elements/element'

require 'ax_elements/accessibility/language'

# Mix the language methods in to the TopLevel
include Accessibility::Language

##
# The Mac OS X dock application.
#
# @return [AX::Application]
AX::DOCK = Accessibility.application_with_bundle_identifier 'com.apple.dock'
