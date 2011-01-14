module AX

# Some additional constructors and factories for Application objects.
class Application < AX::Element

  # @return [Fixnum] the process identifier of the app
  attr_reader :pid

  # We need to cache the PID and register for notifications.
  def initialize app
    super app
    get_pid
  end

  # This is the standard way of creating an application object. It will launch
  # the app if it is not already running.
  # @param [String] bundle
  # @return [AX::Application]
  def self.application_with_bundle_identifier bundle
    while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
      launch_application bundle
      sleep 8
    end
    application_for_pid apps.first.processIdentifier
  end

  # You can call this method to create the application object if the app is
  # already running; otherwise the object creation will fail.
  # @param [Fixnum] pid The process identifier for the application you want
  # @return [AX::Application]
  def self.application_for_pid pid
    Element.make_element AXUIElementCreateApplication(pid)
  end

  # The inherited #get_focus will not work for applications.
  # @return [true]
  def get_focus
    AX::DOCK.list.application_dock_item(title:'Mail').press
  end

  # Create and return a notification observer for the object's application.
  # @param [Proc] callback
  # @return [AXObserverRef]
  def observer callback
    observer = Pointer.new '^{__AXObserver}'
    log_error AXObserverCreate( @pid, callback, observer )
    observer[0]
  end


  private

  # This method uses asynchronous method calls to launch applications.
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
