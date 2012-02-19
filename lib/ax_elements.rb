# Mix the language methods into the TopLevel
require 'accessibility/dsl'
include Accessibility::DSL

##
# The Mac OS X dock application.
#
# @return [AX::Application]
AX::DOCK = app_with identifier: 'com.apple.dock'

require 'ax/button'
require 'ax/radio_button'
require 'ax/row'
require 'ax/static_text'
