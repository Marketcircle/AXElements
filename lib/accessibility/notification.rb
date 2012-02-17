##
# A convenient wrapper around {Accessibility::Core} notification methods.
#
# It is expected that you will mix this in to a class that also has had
# {Accessibility::Core} or equivalent methods implemented.
module Accessibility::Notification

  ##
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
  #   register_to_receive(KAXWindowCreatedNotification, from: safari) { |notif, element|
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
  def register notif, &block
    callback = create_callback_for block
    observer = observer_for @ref, &callback
    source   = run_loop_source_for observer
    register observer, to_receive: notif, for: @ref
    @notifs[notif] = [observer, source]
  end

  # @todo What are the implications of not removing the run loop source?
  #       Taking it out would clobber other notifications that are using
  #       the same source, so we would have to check if we can remove it.
  #
  def unregister notif
    unless @notifs.has_key? notif
      raise ArgumentError, "You have no registrations for #{notif}"
    end
    observer, source = @notifs.delete notif
    unregister observer, from_receiving: notif, for: @ref
  end

  ##
  # Cancel _all_ notification registrations. Simple and clean, but a
  # blunt tool at best. This will have to do for the time being...
  #
  # @return [nil]
  def unregister_all
    @notifs.keys.each do |notif|
      unregister notif
    end
  end


  private

  def create_callback_for proc
    # we are ignoring the context pointer since this is OO
    Proc.new do |observer, sender, received_notif, _|
      break unless proc.call(received_notif, sender)
      unregister received_notif
      CFRunLoopStop(run_loop)
    end
  end

end
