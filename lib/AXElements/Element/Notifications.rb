module AX

class Element

  ##
  # @todo turn this into a proc and dispatch it from within
  #       the {#wait_for_notification} method
  # @todo only stop if the proc returns true or there is no proc
  # @todo fix documentation about refcon
  #
  # @param [AXObserverRef] observer the observer being notified
  # @param [AXUIElementRef] element the element being referenced
  # @param [String] notif the notification name
  # @param [Object] refcon some context object that you can pass around
  def notif_method observer, element, notif, refcon
    if @notif_proc
      wrapped_element = AX.element_attribute(element)
      @notif_proc.call( wrapped_element, notif )
      @notif_proc     = nil
    end

    run_loop   = CFRunLoopGetCurrent()
    app_source = AXObserverGetRunLoopSource( observer )

    CFRunLoopRemoveSource( run_loop, app_source, KCFRunLoopDefaultMode )
    CFRunLoopStop(run_loop)
  end

  ##
  # @todo kAXUIElementDestroyedNotification look at it for catching
  #       windows that disappear
  # @todo add refcon to yielded params
  # @todo replace callback method with a proc (that contains the passed block)
  #
  # [Notifications](../../file/Notifications.markdown) are a way to put
  # non-polling delays into your scripts (sorta).
  #
  # Pause execution of the program until a notification is received or a
  # timeout occurs.
  #
  # You can optionally pass a block to this method to validate the
  # notification.
  #
  # @param [String] notif the name of the notification
  # @param [Float] timeout
  # @yield The block will yield the notification and sender if a block is
  #        given to this method
  # @yieldparam [AX::Element] element the element that sent the notification
  # @yieldparam [String] notif the name of the notification
  # @return [Boolean] true if the notification was received, otherwise false
  def wait_for_notification notif, timeout = 10
    @notif_proc  = Proc.new if block_given?
    callback     = method(:notif_method)
    observer     = Application.application_for_pid( pid ).observer callback

    run_loop     = CFRunLoopGetCurrent()
    app_run_loop = AXObserverGetRunLoopSource( observer )

    AX.log_ax_call( AXObserverAddNotification(observer, @ref, notif, nil) )
    CFRunLoopAddSource( run_loop, app_run_loop, KCFRunLoopDefaultMode )

    # use RunInMode because it has timeout functionality; this method
    # actually has 4 return values, but only two codes will occur under
    # regular circumstances
    CFRunLoopRunInMode( KCFRunLoopDefaultMode, timeout, false ) == 2
  end

end
end
