module AX

# Some additional constructors and factories for Application objects.
class Application < AX::Element

  # This is the standard way of creating an application object. It will launch
  # the app if it is not already running.
  # @param [String] bundle
  # @return [AX::Application]
  def self.application_with_bundle_identifier bundle
    while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
      launch_application bundle
      sleep 2
    end
    application_for_pid apps.first.processIdentifier
  end

  # You can call this method to create the application object if the app is
  # already running; otherwise the object creation will fail.
  # @param [Fixnum] pid The process identifier for the application you want
  # @return [AX::Application]
  def self.application_for_pid pid
    Element.make_element AXUIElementCreateApplication( pid )
  end

  # The inherited {Element#get_focus} will not work for applications.
  # @param [String] title the title of the application in the dock
  # @return [Boolean] true if successful, otherwise false
  def get_focus title
    AX::DOCK.list.application_dock_item(title:title).press
  end

  # Create and return a notification observer for the object's application.
  # @param [Proc] callback
  # @return [AXObserverRef]
  def observer callback
    observer = Pointer.new '^{__AXObserver}'
    log AXObserverCreate( pid, callback, observer )
    observer[0]
  end


  private

  # This method uses asynchronous method calls to launch applications.
  # @param [String] bundle the bundle identifier for the app
  # @return [Boolean]
  def self.launch_application bundle
    AX.log.info "Launching app with bundleID '#{bundle}'"
    NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier bundle,
                                                      options:NSWorkspaceLaunchAsync,
                               additionalEventParamDescriptor:nil,
                                             launchIdentifier:nil
  end
end

end
