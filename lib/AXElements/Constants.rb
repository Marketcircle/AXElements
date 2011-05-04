module AX

  # @return [AX::SystemWide]
  SYSTEM = element_attribute AXUIElementCreateSystemWide()

  # @return [AX::Application] the Mac OS X dock application
  DOCK = Application.application_with_bundle_identifier 'com.apple.dock'

  # @return [AX::Application] the Mac OS X Finder application
  FINDER = Application.application_with_bundle_identifier 'com.apple.finder'

end
