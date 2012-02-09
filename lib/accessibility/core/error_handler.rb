# -*- coding: utf-8 -*-
module Accessibility::Core


  private

  # @return [Hash{Number=>Array(Symbol,Range)}]
  AXERROR = {
    KAXErrorFailure                           => [:handle_failure,                0...1],
    KAXErrorIllegalArgument                   => [:handle_illegal_argument,       0..-1],
    KAXErrorInvalidUIElement                  => [:handle_invalid_element,        0...1],
    KAXErrorInvalidUIElementObserver          => [:handle_invalid_observer,       0...3],
    KAXErrorCannotComplete                    => [:handle_cannot_complete,        0...1],
    KAXErrorAttributeUnsupported              => [:handle_attr_unsupported,       0...2],
    KAXErrorActionUnsupported                 => [:handle_action_unsupported,     0...2],
    KAXErrorNotificationUnsupported           => [:handle_notif_unsupported,      0...2],
    KAXErrorNotImplemented                    => [:handle_not_implemented,        0...1],
    KAXErrorNotificationAlreadyRegistered     => [:handle_notif_registered,       0...2],
    KAXErrorNotificationNotRegistered         => [:handle_notif_not_registered,   0...2],
    KAXErrorAPIDisabled                       => [:handle_api_disabled,           0...0],
    KAXErrorParameterizedAttributeUnsupported => [:handle_param_attr_unsupported, 0...2],
    KAXErrorNotEnoughPrecision                => [:handle_not_enough_precision,   0...0]
  }

  # @param [Number]
  def handle_error code, *args
    args[0]       = args[0].description if args.first
    handler, argc = AXERROR[code]
    klass, msg = if handler
                   self.send handler, *args[argc]
                 else
                   [RuntimeError, "You should never reach this line [#{code.inspect}]"]
                 end
    raise klass, msg, caller(1)
  end

  def handle_failure ref
    msg = "A system failure occurred with #{ref}, stopping to be safe"
    [RuntimeError, msg]
  end

  def handle_illegal_argument *args
    msg = case args.size
          when 1
            "#{args.first} is not an AXUIElementRef"
          when 2
            "Either the element #{args.first} " +
              "or the attr/action/callback #{args.second.inspect} " +
              'is not a legal argument'
          when 3
            "You can't set #{args.second.inspect} to " +
              "#{args.third.description.inspect} for #{args.first}"
          when 4
            "The point [#{args.second}, #{args.third}] is not a valid point, " +
              "or #{args.first} is not an AXUIElementRef"
          when 5
            "Either the observer #{args.third.description}, " +
              "the element #{args.first}, or " +
              "the notification #{args.second.inspect} " +
              "is not a legitimate argument"
          end
    [ArgumentError, msg]
  end

  def handle_invalid_element ref
    [ArgumentError, "#{ref} is no longer a valid reference"]
  end

  def handle_invalid_observer ref, lol, observer
    msg  = "#{observer.description} is no longer a valid observer "
    msg << "for #{ref}, or was never valid"
    [ArgumentError, msg]
  end

  # @param [AXUIElementRef]
  def handle_cannot_complete ref
    spin_run_loop
    pid = pid_for ref
    app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    msg = if app
            "Some unspecified error occurred using #{ref} with AXAPI, possibly a timeout. :("
          else
            "Application for pid=#{pid} is no longer running. Maybe it crashed?"
          end
    [RuntimeError, msg]
  end

  def handle_attr_unsupported ref, attr
    msg = "#{ref} does not have a #{attr.inspect} attribute"
    [ArgumentError, msg]
  end

  def handle_action_unsupported ref, action
    msg = "#{ref} does not have a #{action.inspect} action"
    [ArgumentError, msg]
  end

  def handle_notif_unsupported ref, notif
    msg = "#{ref} does not support the #{notif.inspect} notification"
    [ArgumentError, msg]
  end

  def handle_not_implemented ref
    msg  = "The program that owns #{ref} does not work with AXAPI properly"
    [NotImplementedError, msg]
  end

  ##
  # @todo Does this really neeed to raise an exception? Seems
  #       like a warning would be sufficient.
  def handle_notif_registered ref, notif
    msg  = "You have already registered to hear about #{notif.inspect} "
    msg << "from #{ref}"
    [ArgumentError, msg]
  end

  def handle_notif_not_registered ref, notif
    msg = "You have not registered to hear about #{notif.inspect} from #{ref}"
    [RuntimeError, msg]
  end

  def handle_api_disabled
    [RuntimeError, 'AXAPI has been disabled']
  end

  def handle_param_attr_unsupported ref, attr
    [ArgumentError, "#{ref} does not have a #{attr.inspect} parameterized attribute"]
  end

  def handle_not_enough_precision
    [RuntimeError, "AXAPI said there was not enough precision ¯\(°_o)/¯"]
  end

end
