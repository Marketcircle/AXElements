##
# @todo This module needs a better name
#
# A collection of helper methods for working with AXElements.
module Accessibility

class << self

  ##
  # Get a list of elements, starting with the element you gave and riding
  # all the way up the hierarchy to the top level (should be the Application).
  #
  # @param [AX::Element] element
  # @return [Array<AX::Element>] the hierarchy in ascending order
  def hierarchy *elements
    element = elements.last
    return hierarchy(elements << element.parent) if element.respond_to?(:parent)
    return elements
  end

  ##
  # Finds the current mouse position and then calls {#element_at_position}.
  #
  # @return [AX::Element]
  def element_under_mouse
    AX.element_at_position NSEvent.mouseLocation.carbonize!
  end

  ##
  # @todo Find a way for this method to work without sleeping;
  #       consider looping begin/rescue/end until AX starts up
  # @todo Search NSWorkspace.sharedWorkspace.runningApplications ?
  # @todo this does not handle bad bundle identifier's very well
  #
  # This is the standard way of creating an application object. It will
  # launch the app if it is not already running and then create the
  # accessibility object.
  #
  # However, this method is a HUGE hack in cases where the app is not
  # already running; I've tried to register for notifications, launch
  # synchronously, etc., but there is always a problem with accessibility
  # not being ready. Hopefully this problem will go away on Lion...
  #
  # If this method fails to find an app with the appropriate bundle
  # identifier then it will return nil, eventually.
  #
  # @param [String] bundle
  # @param [Float] timeout how long to wait between polling
  # @return [AX::Application,nil]
  def application_for_bundle_identifier bundle, sleep_time
    sleep_count = 0
    while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
      launch_application bundle
      return if sleep_count > 10
      sleep sleep_time
      sleep_count += 1
    end
    AX.application_for_pid( apps.first.processIdentifier )
  end

  # @param [String] name name of the application to launch
  def application_with_name name
    raise NotImplementedError
  end


  private

  ##
  # This method uses asynchronous method calls to launch applications.
  #
  # @param [String] bundle the bundle identifier for the app
  # @return [Boolean]
  def launch_application bundle
    AX.log.info "Launching app with bundleID '#{bundle}'"
    NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier  bundle,
                                                      options: NSWorkspaceLaunchAsync,
                               additionalEventParamDescriptor: nil,
                                             launchIdentifier: nil
  end

end
end
