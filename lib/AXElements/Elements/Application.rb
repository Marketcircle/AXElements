module AX

##
# Some additional constructors and conveniences for Application objects.
class Application < AX::Element

  include Traits::Typing

  class << self

    ##
    # @todo Find a way for this method to work without sleeping
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
    # @param [String] bundle
    # @param [Float] timeout how long to wait between polling
    # @return [AX::Application]
    def self.application_with_bundle_identifier bundle, sleep_time = 2
      while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
        launch_application bundle
        sleep sleep_time
      end
      application_for_pid apps.first.processIdentifier
    end

    ##
    # You can call this method to create the application object if the app is
    # already running; otherwise the object creation will fail.
    #
    # @param [Fixnum] pid The process identifier for the application you want
    # @return [AX::Application]
    def self.application_for_pid pid
      AX.make_element AXUIElementCreateApplication( pid )
    end


    private

    ##
    # This method uses asynchronous method calls to launch applications.
    #
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


  ##
  # @todo This method needs a fall back procedure if the app does not
  #       have a dock icon
  #
  # The inherited {Element#get_focus} will not work for applications,
  # so we will just get focus by "clicking" the dock icon for the app.
  #
  # @return [Boolean] true if successful, otherwise unpredictable
  def get_focus
    AX::DOCK.list.application_dock_item(title: title).press
  end

  ##
  # @todo Since this does not use internal state, it is a candidate to be
  #       moved to a utility class
  #
  # A macro for showing the About window for an app
  def show_about_window
    self.get_focus
    self.menu_bar_item(title:(self.title)).press
    self.menu_bar.menu_item(title: "About #{self.title}").press
  end

  ##
  # Create and return a notification observer for the object's application.
  # This method is almost never directly called, it is instead called by
  # {Traits::Notifications#wait_for_notification}.
  #
  # @param [Proc] callback
  # @return [AXObserverRef]
  def observer callback
    observer = Pointer.new '^{__AXObserver}'
    log AXObserverCreate( pid, callback, observer )
    observer[0]
  end

  ##
  # Override the base class to make sure the pid is included
  def inspect
    (super).sub />$/, "@pid=#{self.pid}>"
  end

end

end
