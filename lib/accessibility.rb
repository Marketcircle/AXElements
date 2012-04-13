require 'ax/application'

##
# The main AXElements namespace.
module Accessibility
class << self

  # @group Finding an application object

  ##
  # @todo Move to {AX::Aplication#initialize} eventually.
  # @todo Find a way for this method to work without sleeping;
  #       consider looping begin/rescue/end until AX starts up
  # @todo This needs to handle bad bundle identifier's gracefully
  #
  # This is the standard way of creating an application object. It will
  # launch the app if it is not already running and then create the
  # accessibility object.
  #
  # However, this method is a _HUGE_ hack in cases where the app is not
  # already running; I've tried to register for notifications, launch
  # synchronously, etc., but there is always a problem with accessibility
  # not being ready.
  #
  # If this method fails to find an app with the appropriate bundle
  # identifier then it will return nil, eventually.
  #
  # @example
  #
  #   application_with_bundle_identifier 'com.apple.mail' # wait a few seconds
  #   application_with_bundle_identifier 'com.marketcircle.Daylite'
  #
  # @param [String] bundle a bundle identifier
  # @return [AX::Application,nil]
  def application_with_bundle_identifier bundle
    10.times do
      app = NSRunningApplication.runningApplicationsWithBundleIdentifier(bundle)
      return AX::Application.new(app) if app
      launch_application bundle
      sleep 2
    end
    nil
  end

  ##
  # @deprecated Use {AX::Application.new} instead.
  #
  # Get the accessibility object for an application given its localized
  # name. This will only work if the application is already running.
  #
  # @example
  #
  #   application_with_name 'Mail'
  #
  # @param [String] name name of the application to launch
  # @return [AX::Application,nil]
  def application_with_name name
    AX::Application.new name
  end

  # @endgroup


  private

  ##
  # Asynchronously launch an application given the bundle identifier.
  #
  # @param [String] bundle the bundle identifier for the app
  # @return [Boolean]
  def launch_application bundle
    NSWorkspace.sharedWorkspace.launchAppWithBundleIdentifier bundle,
                                                     options: NSWorkspaceLaunchAsync,
                              additionalEventParamDescriptor: nil,
                                            launchIdentifier: nil
  end

end
end
