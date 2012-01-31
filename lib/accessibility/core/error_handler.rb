module Accessibility::Core


  private

  # @param [Number]
  def handle_error code, *args
    description = args.first.description if args.first
    case code
    when KAXErrorIllegalArgument
      msg = case args.size
            when 1
              "'#{description}' is not an AXUIElementRef"
            when 2
              "Either the element '#{description}' " +
                "or the attr/action/callback '#{args.second}' is not a legal argument"
            when 3
              "You can't set '#{args.second}' to '#{CFCopyDescription(args.third)}' " +
                "for '#{description}'"
            when 4
              "The point [#{args.second}, #{args.third}] is not a valid point, or " +
                "'#{description}' is not an AXUIElementRef"
            when 5
              "Either the observer '#{CFCopyDescription(args.third)}', " +
                "the element '#{description}', or " +
                "the notification '#{args.second}' is not a legitimate argument"
            end
      raise ArgumentError, msg
    when KAXErrorInvalidUIElement
      msg = "'#{description}' is no longer a valid token"
      raise RuntimeError, msg
    when KAXErrorAttributeUnsupported
      msg = "'#{description}' doesn't have '#{args.second}'"
      raise ArgumentError, msg
    when KAXErrorActionUnsupported
      msg = "'#{description}' doesn't have '#{args.second}'"
      raise ArgumentError, msg
    when KAXErrorParameterizedAttributeUnsupported then
      msg = "'#{description}' does not have parameterized attributes"
      raise ArgumentError, msg
    when KAXErrorFailure
      msg = 'Some kind of system failure occurred, stopping to be safe'
      raise RuntimeError, msg
    when KAXErrorCannotComplete
      handle_cannot_complete args.first
    when KAXErrorNotImplemented
      msg  = "The program that owns '#{description}' "
      msg << 'does not work with AXAPI properly'
      raise NotImplementedError, msg
    when KAXErrorNotEnoughPrecision
      raise RuntimeError, 'AXAPI said there was not enough precision'
    when KAXErrorAPIDisabled
      raise RuntimeError, 'AXAPI has been disabled'
    when KAXErrorInvalidUIElementObserver
      msg  = "'#{CFCopyDescription(args.third)}' is no longer valid or "
      msg << 'was never valid'
      raise ArgumentError, msg
    when KAXErrorNotificationUnsupported
      msg = "'#{description}' doesn't support notifications"
      raise ArgumentError, msg
    when KAXErrorNotificationAlreadyRegistered
      # @todo Does this really neeed to raise an exception? Seems
      #       like a warning would be sufficient.
      msg  = "You have already registered to hear about '#{args.second}' "
      msg << "from '#{description}'"
      raise ArgumentError, msg
    when KAXErrorNotificationNotRegistered
      msg  = "You have not yet registered to hear about '#{args.second}' "
      msg << "from '#{description}'"
      raise RuntimeError, msg
    else
      raise "You should never reach this line! [#{code.inspect}]"
    end
  end

  # @param [AXUIElementRef]
  def handle_cannot_complete ref
    NSRunLoop.currentRunLoop.runUntilDate Time.now
    pid = pid_for ref
    app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    msg = if app
            'Some unspecified error occurred with AXAPI, possibly a timeout. :('
          else
            "Application for pid=#{pid} is no longer running. Maybe it crashed?"
          end
    raise RuntimeError, msg
  end

end
