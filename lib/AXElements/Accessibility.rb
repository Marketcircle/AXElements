class << Accessibility

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
    AX.element_at_point *NSEvent.mouseLocation.carbonize!
  end

  ##
  #
  #
  # @overload element_at_point(x,y)
  #   @param [Float] x
  #   @param [Float] y
  # @overload element_at_point([x,y])
  #   @param [Array(Float,Float)] point
  # @overload element_at_point(CGPoint.new(x,y))
  #   @param [CGPoint] point
  def element_at_point *point
    AX.element_at_position(*point.to_a.flatten)
  end
  alias_method :element_at_position, :element_at_point

  ##
  # @todo Find a way for this method to work without sleeping;
  #       consider looping begin/rescue/end until AX starts up
  # @todo This needs to handle bad bundle identifier's gracefully
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
  # @param [String] bundle a bundle identifier
  # @param [Float] sleep_time how long to wait between polling
  # @return [AX::Application,nil]
  def application_with_bundle_identifier bundle, sleep_time = 2
    sleep_count = 0
    while (apps = NSRunningApplication.runningApplicationsWithBundleIdentifier bundle).empty?
      launch_application bundle
      return if sleep_count > 10
      sleep sleep_time
      sleep_count += 1
    end
    application_with_pid apps.first.processIdentifier
  end

  ##
  # Get the accessibility object for an application given its localized
  # name.
  #
  # @param [String] name name of the application to launch
  # @return [AX::Application,nil]
  def application_with_name name
    apps  = NSWorkspace.sharedWorkspace.runningApplications
    index = apps.map(&:localizedName).index(name)
    AX.application_for_pid(apps[index].processIdentifier) if index
  end

  ##
  # Get the accessibility object for an application given its PID.
  #
  # @return [AX::Application]
  def application_with_pid pid
    AX.application_for_pid(pid)
  end


  private

  ##
  # This method uses asynchronous method calls to launch applications.
  #
  # @param [String] bundle the bundle identifier for the app
  # @return [Boolean]
  def launch_application bundle
    log.info "Launching app with bundleID '#{bundle}'"
    NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier  bundle,
                                                      options: NSWorkspaceLaunchAsync,
                               additionalEventParamDescriptor: nil,
                                             launchIdentifier: nil
  end

end
