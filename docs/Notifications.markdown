# Notifications

@todo Need to finish this soon...

Notifications are a tool that you can use to add a delay in script
that waits until a certain event happens, such as waiting for a window
to be created or a menu to be opened.

You can find a list of built in notifications in Apple's [documentation](http://developer.apple.com/library/mac/#documentation/Accessibility/Reference/AccessibilityLowlevel/AXNotificationConstants_h/index.html).

Using the notifications system in AXElements is a two step procedure;
first you register to receive a notification, and then you wait to
receive it. This is so that you can execute the code in between that
would actually trigger the notification to be fired.

## Example

Consider a log in window; you enter some credentials and then you
press a button to log in and load up the main application window.

This procedure is most likely asynchronous, so your script would have
to wait until the main application window loaded. How?

You could just use Kernel#sleep, but how long should you sleep for and
how reliable is that? How much time would that waste?

In step notifications; it turns out that whenever a window is created,
the application sends out a notification to any accessibility
applications that are listening letting them know a window was created
and the notification will include the accessibility object and the
notification name. Using this system, we can just wait for the
notification to be received and continue executing the script right
away (ok, sometimes there can be a 1-2 ms delay).

     register_for_notification app, :window_created
     login # trigger an action that will eventually send a notification
     wait_for_notification
