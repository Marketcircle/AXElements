# -*- coding: utf-8 -*-
module Accessibility::Core


  private

  # @return [Hash{Number=>Array(Symbol,Range)}]
  AXERROR = {
    KAXErrorFailure                           =>
      [RuntimeError,        :handle_failure,                0...1],
    KAXErrorIllegalArgument                   =>
      [ArgumentError,       :handle_illegal_argument,       0..-1],
    KAXErrorInvalidUIElement                  =>
      [ArgumentError,       :handle_invalid_element,        0...1],
    KAXErrorInvalidUIElementObserver          =>
      [ArgumentError,       :handle_invalid_observer,       0...3],
    KAXErrorCannotComplete                    =>
      [RuntimeError,        :handle_cannot_complete,        0...1],
    KAXErrorAttributeUnsupported              =>
      [ArgumentError,       :handle_attr_unsupported,       0...2],
    KAXErrorActionUnsupported                 =>
      [ArgumentError,       :handle_action_unsupported,     0...2],
    KAXErrorNotificationUnsupported           =>
      [ArgumentError,       :handle_notif_unsupported,      0...2],
    KAXErrorNotImplemented                    =>
      [NotImplementedError, :handle_not_implemented,        0...1],
    KAXErrorNotificationAlreadyRegistered     =>
      [ArgumentError,       :handle_notif_registered,       0...2],
    KAXErrorNotificationNotRegistered         =>
      [RuntimeError,        :handle_notif_not_registered,   0...2],
    KAXErrorAPIDisabled                       =>
      [RuntimeError,        :handle_api_disabled,           0...0],
    KAXErrorParameterizedAttributeUnsupported =>
      [ArgumentError,       :handle_param_attr_unsupported, 0...2],
    KAXErrorNotEnoughPrecision                =>
      [RuntimeError,        :handle_not_enough_precision,   0...0]
  }

  # @param [Number]
  def handle_error code, *args
    args[0]              = args[0].description if args[0]
    klass, handler, argc = AXERROR[code]
    msg = if handler
            self.send handler, *args[argc]
          else
            klass = RuntimeError
            "You should never reach this line [#{code.inspect}]"
          end
    raise klass, msg, caller(1)
  end

  # @private
  def handle_failure ref
    "A system failure occurred with #{ref}, stopping to be safe"
  end

  # @private
  def handle_illegal_argument *args
    case args.size
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
  end

  # @private
  def handle_invalid_element ref
    "#{ref} is no longer a valid reference"
  end

  # @private
  def handle_invalid_observer ref, lol, observer
    "#{observer.description} is no longer a valid observer for #{ref}, or was never valid"
  end

  # @private
  # @param [AXUIElementRef]
  def handle_cannot_complete ref
    spin_run_loop
    pid = pid_for ref
    app = NSRunningApplication.runningApplicationWithProcessIdentifier pid
    if app
      "Some unspecified error occurred using #{ref} with AXAPI, possibly a timeout. :("
    else
      "Application for pid=#{pid} is no longer running. Maybe it crashed?"
    end
  end

  # @private
  def handle_attr_unsupported ref, attr
    "#{ref} does not have a #{attr.inspect} attribute"
  end

  # @private
  def handle_action_unsupported ref, action
    "#{ref} does not have a #{action.inspect} action"
  end

  # @private
  def handle_notif_unsupported ref, notif
    "#{ref} does not support the #{notif.inspect} notification"
  end

  # @private
  def handle_not_implemented ref
    "The program that owns #{ref} does not work with AXAPI properly"
  end

  ##
  # @private
  # @todo Does this really neeed to raise an exception? Seems
  #       like a warning would be sufficient.
  def handle_notif_registered ref, notif
    "You have already registered to hear about #{notif.inspect} from #{ref}"
  end

  # @private
  def handle_notif_not_registered ref, notif
    "You have not registered to hear about #{notif.inspect} from #{ref}"
  end

  # @private
  def handle_api_disabled
    'AXAPI has been disabled'
  end

  # @private
  def handle_param_attr_unsupported ref, attr
    "#{ref} does not have a #{attr.inspect} parameterized attribute"
  end

  # @private
  def handle_not_enough_precision
    "AXAPI said there was not enough precision ¯\(°_o)/¯"
  end

end
