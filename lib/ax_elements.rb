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


require 'ax_elements/version'
require 'accessibility'
# @todo How to load the other default classes?


# @todo Change 'language' to 'dsl'
# Mix the language methods in to the TopLevel
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
