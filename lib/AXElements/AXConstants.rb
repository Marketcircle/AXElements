module AX

  @prefix = /[A-Z]+([A-Z][a-z])/

  # @return [AX::SystemWide]
  SYSTEM = element_attribute AXUIElementCreateSystemWide()

  # @return [AX::Application] the Mac OS X dock application
  DOCK = Application.application_with_bundle_identifier 'com.apple.dock'

  # @return [AX::Application] the Mac OS X Finder application
  FINDER = Application.application_with_bundle_identifier 'com.apple.finder'

  # @todo provide a default object for Spotlight (hard since AX is not properly
  #       implemented for it)

end
