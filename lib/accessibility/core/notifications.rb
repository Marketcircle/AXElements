##
# Special module just for notifications. In order to mix this module in, you
# will need to implement the following:
#
#   - pid_of(element)
#   - invalid_message(observer)
#   - failure_message
#   - cannot_complete_message
#
# This module is designed to be mixed into {Accessibility::Core}.
module Accessibility::Core

  ##
  # Implementation of `#extended` callback so that the `notifs` attribute
  # gets initialized.
  def self.extended modul
    modul.instance_variable_set(:@notifs, {})
  end


  private

  ##
  # Cache of notifications that are actively registered. Each
  # key-value pair contains all the information needed in order to
  # unregister a notification later. They key is the observer as
  # that is the only data that is guaranteed to be unique.
  #
  # @return [Hash{AXObserverRef=>Array(String, AXUIElementRef)}]
  attr_reader :notifs

  ##
  # @todo This method is too big, needs refactoring into its own class.
  #
  # Register to receive notification of the given event being completed
  # by the given element.
  #
  # {file:docs/Notifications.markdown Notifications} are a way to put
  # non-polling delays into your scripts.
  #
  # Use this method to register to be notified of the specified event in
  # an application. You must also pass a block to this method to validate
  # the notification.
  #
  # @example
  #
  #   register_for(KAXWindowCreatedNotification, from: safari) { |notif, element|
  #     puts "#{element.description} sent #{notif.inspect}"
  #     true
  #   }
  #
  # @param [String] notif the name of the notification
  # @param [AXUIElementRef] element the element which will send the notification
  # @yield Validate the notification; the block should return truthy if
  #        the notification received is the expected one and the script can stop
  #        waiting, otherwise should return falsy.
  # @yieldparam [String] notif the name of the notification
  # @yieldparam [AXUIElementRef] element the element that sent the notification
  # @yieldreturn [Boolean] determines if the script should continue or wait
  # @return [Array(Observer, String, AXUIElementRef)] the registration triple
  def register_for notif, from: element, &block
    run_loop = CFRunLoopGetCurrent()

    # we are ignoring the context pointer since this is OO
    callback = Proc.new do |observer, sender, received_notif, _|
      LOCK.synchronize do
        break if     @notifs.empty?
        break unless block.call(received_notif, sender)

        loop_source = AXObserverGetRunLoopSource(observer)
        CFRunLoopRemoveSource(run_loop, loop_source, KCFRunLoopDefaultMode)
        unregister observer, from_receiving: received_notif, from: sender
        CFRunLoopStop(run_loop)
      end
    end

    new_observer = observer_for element, calling: callback
    loop_source  = AXObserverGetRunLoopSource(dude)
    register new_observer, to_receive: notif, from: element
    CFRunLoopAddSource(run_loop, loop_source, KCFRunLoopDefaultMode)

    # must cache the triple of info in order to do unregistration
    @notifs[new_observer] = [notif, element]
    [new_observer, notif, element]
  end

  ##
  # Pause execution of the program until a notification is received or a
  # timeout occurs.
  #
  # @example
  #
  #   wait 60.0
  #
  # @param [Float]
  # @return [Boolean] true if the notification was received, otherwise false
  def wait timeout
    # We use RunInMode because it has timeout functionality, return values are
    case CFRunLoopRunInMode(KCFRunLoopDefaultMode, timeout, false)
    when KCFRunLoopRunStopped       then true  # Stopped with CFRunLoopStop.
    when KCFRunLoopRunTimedOut      then false # Time interval seconds passed.
    when KCFRunLoopFinished         then       # Mode has no sources or timers.
      raise RuntimeError, 'The run loop was not configured properly'
    when KCFRunLoopRunHandledSource then       # Only applies when returnAfterSourceHandled is true.
      raise RuntimeError, 'Did you start your own run loop?'
    else
      raise 'You just found a bug, might be yours, or OS X, or MacRuby...'
    end
  end

  ##
  # Cancel _all_ notification registrations. Simple and clean, but a
  # blunt tool at best. This will have to do for the time being...
  #
  # @return [nil]
  def unregister_notifs
    LOCK.synchronize do
      @notifs.each_pair do |observer, pair|
        unregister observer, from_receiving: pair.first, from: pair.last
      end
      @notifs = {}
    end
  end

  ##
  # Create and return a notification observer for the given object's
  # application.
  #
  # @param [AXUIElementRef] element
  # @param [Method,Proc] callback
  # @return [AXObserverRef]
  def observer_for element, calling: callback
    ptr  = Pointer.new OBSERVER
    case AXObserverCreate(pid_for(element), callback, ptr)
    when KAXErrorSuccess         then ptr[0]
    when KAXErrorIllegalArgument then
      msg  = "Either '#{CFCopyDescription(element)}' or "
      msg << "'#{callback.inspect}' is not a valid argument"
      raise ArgumentError, msg
    when KAXErrorFailure         then failure_message
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # Register a notification observer for a specific event.
  #
  # @param [AXObserverRef]
  # @param [String]
  # @param [AX::Element]
  def register observer, to_receive: notif, from: element
    case AXObserverAddNotification(observer, element, notif, nil)
    when KAXErrorSuccess                       then true
    when KAXErrorInvalidUIElementObserver      then invalid_message(observer)
    when KAXErrorIllegalArgument               then
      msg  = "Either '#{CFCopyDescription(observer)}', "
      msg << "'#{CFCopyDescription(element)}', or '#{notif}' is not valid"
      raise ArgumentError, msg
    when KAXErrorNotificationUnsupported       then
      msg = "'#{CFCopyDescription(element)}' doesn't support notifications"
      raise ArgumentError, msg
    when KAXErrorNotificationAlreadyRegistered then
      # @todo Does this really neeed to raise an exception? Seems
      #       like a warning would be sufficient.
      msg  = "You have already registered to hear about '#{notif}' "
      msg << "from '#{CFCopyDescription(element)}'"
      raise ArgumentError, msg
    when KAXErrorCannotComplete                then cannot_complete_message
    when KAXErrorFailure                       then failure_message
    else
      raise 'You should never reach this line'
    end
  end

  ##
  # Unregister a notification that has been previously setup.
  #
  # @param [AXObserverRef]
  # @param [String]
  # @param [AX::Element]
  def unregister observer, from_receiving: notif, from: element
    case AXObserverRemoveNotification(observer, ref, notif)
    when KAXErrorSuccess                    then true
    when KAXErrorNotificationNotRegistered  then
      raise RuntimeError, 'Notif was not registered to begin with...'
    when KAXErrorIllegalArgument            then
      msg  = "Either the observer '#{CFCopyDescription(observer)}', "
      msg << "the element '#{CFCopyDescription(ref)}', or "
      msg << "the notification '#{notif}' is not a legitimate argument"
      raise ArgumentError, msg
    when KAXErrorInvalidUIElementObserver   then
      msg  = "'#{CFCopyDescription(observer)}' is no longer valid or "
      msg << 'was never valid'
      raise ArgumentError, msg
    when KAXErrorIllegalArgument            then
      msg  = "Either '#{CFCopyDescription(observer)}', "
      msg << "'#{CFCopyDescription(element)}', or '#{notif}' is not valid"
      raise ArgumentError, msg
    when KAXErrorNotificationUnsupported    then
      msg = "'#{CFCopyDescription(element)}' does not support notifications"
      raise NoMethodError, msg
    when KAXErrorNotificationNotRegistered  then
      msg  = "You have not yet registered to hear about '#{notif}' "
      msg << "from '#{CFCopyDescription(element)}'"
      raise RuntimeError, msg
    when KAXErrorCannotComplete             then cannot_complete_message
    when KAXErrorFailure                    then failure_message
    else
      raise 'You should never reach this line!'
    end
  end

  ##
  # @todo Would a Dispatch::Semaphore be better?
  #
  # Semaphore used to synchronize async notification stuff.
  #
  # @return [Mutex]
  LOCK     = Mutex.new

  ##
  # @private
  #
  # `Pointer` type encoding for `AXObserverRef` objects.
  #
  # @return [String]
  OBSERVER = '^{__AXObserver}'.freeze

end
