# Mix the language methods into the TopLevel
require 'accessibility/dsl'
include Accessibility::DSL

##
# The Mac OS X dock application.
#
# @return [AX::Application]
AX::DOCK = AX::Application.new('com.apple.dock')

# Load explicitly defined elements that are optional
require 'ax/button'
require 'ax/radio_button'
require 'ax/row'
require 'ax/static_text'

# Misc things that we need to load
require 'ax_elements/nsarray_compat'
# require 'ax_elements/exception_workaround' # disable for now
