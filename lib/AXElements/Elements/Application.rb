module AX

# Some additional constructors and factories for Application objects.
class Application < AX::Element

  # @return [Fixnum] the process identifier of the app
  attr_reader :pid

  # Just so we can cache the PID.
  def initialize app
    super app

    pid  = Poniter.new 'i'
    AXUIElementGetPid(@ref, pid)
    @pid = pid[0]
  end

  # @todo make this method actually wait for Daylite to finish loading,
  #  I should be able to do this with accessibility notifications, so I
  #  should register for notifications when I launch the application
  # @param [String] bundle
  # @return [AX::Application]
  def self.application_with_bundle_identifier bundle
    while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
      launch_application bundle
      sleep 8
    end
    application_for_pid apps.first.processIdentifier
  end

  # @param [Fixnum] pid The process identifier for the application you want
  # @return [AX::Application]
  def self.application_for_pid pid
    Element.make_element AXUIElementCreateApplication(pid)
  end

  # @param [CGPoint] point
  # @return [Element]
  def element_at_position point
    ptr = Pointer.new :id
    err_code = AXUIElementCopyElementAtPosition( @ref, point.x, point.y, ptr )
    log_error err_code unless err_code.zero?
    Element.make_element ptr[0]
  end

  private
  # This is an asynchronous method.
  # @param [String] bundle the bundle identifier for the app
  # @return [boolean]
  def self.launch_application bundle
    NSLog("Launching app with bundleID '#{bundle}'")
    NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier bundle,
                                                      options:NSWorkspaceLaunchAsync,
                               additionalEventParamDescriptor:nil,
                                             launchIdentifier:nil
  end
end

end
