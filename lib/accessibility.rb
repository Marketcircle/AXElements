require 'accessibility/version'
require 'ax/application'

class << Accessibility

  # Initialize the DEBUG value
  @debug = ENV.fetch 'AXDEBUG', $DEBUG

  ##
  # Whether or not to turn on DEBUG features in AXElements. The
  # value is initially inherited from `$DEBUG` but can be overridden
  # by an environment variable named `AXDEBUG` or changed dynamically
  # at runtime.
  #
  # @return [Boolean]
  attr_accessor :debug
  alias_method :debug?, :debug


  # @group Finding an application object

  ##
  # @todo Move to {AX::Aplication#initialize} eventually.
  #
  # This is the standard way of creating an application object. It will
  # launch the app if it is not already running and then create the
  # accessibility object.
  #
  # However, this method is a bit of a hack in cases where the app is not
  # already running; I've tried to register for notifications, launch
  # synchronously, etc., but there is always a problem with accessibility
  # not being ready right away.
  #
  # If this method fails to find an app with the appropriate bundle
  # identifier then it will raise an exception. If the problem was not a
  # typo, then it might mean that the bundle identifier has not been
  # registered with the system yet and you should launch the app once
  # manually.
  #
  # @example
  #
  #   application_with_bundle_identifier 'com.apple.mail' # wait a few seconds
  #   application_with_bundle_identifier 'com.marketcircle.Daylite'
  #
  # @param [String] bundle a bundle identifier
  # @return [AX::Application,nil]
  def application_with_bundle_identifier bundle
    if launch_application bundle
      10.times do
        app = NSRunningApplication.runningApplicationsWithBundleIdentifier(bundle).first
        return AX::Application.new(app) if app
        sleep 1
      end
    else
      raise ArgumentError "Could not launch app matching bundle id `#{bundle}'"
    end
    nil
  end

  ##
  # @deprecated Directly initialize an {AX::Application} instance instead
  #             (e.g. `AX::Application.new('Terminal')`).
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
    $stderr.puts 'DEPRECATED: Use AX::Application.new instead'
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
