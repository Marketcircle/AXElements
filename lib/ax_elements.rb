framework 'Cocoa'

# check that the Accessibility APIs are enabled and are available to MacRuby
begin
  unless AXAPIEnabled()
    raise RuntimeError, <<-EOS
------------------------------------------------------------------------
Universal Access is disabled on this machine.

Please enable it in the System Preferences.
------------------------------------------------------------------------
    EOS
  end
rescue NoMethodError
  raise NotImplementedError, <<-EOS
------------------------------------------------------------------------
You need to install the latest BridgeSupport preview so that AXElements
has access to CoreFoundation.
------------------------------------------------------------------------
  EOS
end


unless Object.const_defined? :KAXIdentifierAttribute
  ##
  # Added for backwards compatability with Snow Leopard.
  # This attribute is standard with Lion and newer. AXElements depends
  # on it being defined.
  #
  # @return [String]
  KAXIdentifierAttribute = 'AXIdentifier'.freeze
end


require 'ax_elements/version'

# Mix the language methods into the TopLevel
require 'accessibility/dsl'
include Accessibility::DSL


##
# The Mac OS X dock application.
#
# @return [AX::Application]
AX::DOCK = Accessibility.application_with_bundle_identifier 'com.apple.dock'

require 'ax/button'
require 'ax/radio_button'
require 'ax/row'
require 'ax/static_text'
