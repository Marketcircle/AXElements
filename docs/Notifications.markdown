# Notifications

Accessibility notifications are a tool that you can use to add a delay
in script that waits until a certain event happens. These events could
be a window being created or a menu being opened.

A notification is much more time efficient than simply using `#sleep`
to estimate how long an action will take to complete. Sleep often
causes you to wait longer than is necessary to avoid waiting less time
than what is needed. With notifications you set a maximum amount of
time that should be waited, called the timeout, but waiting is stopped
as soon as the notification is received. This makes using
notifications preferable to simply sleeping.

An important thing to understand is that an accessibility notification
is separate from a the notifications that are sent and received
internally in a Cocoa app. Accessibility notifications are not
very different in concept, they differ largely in mechanics. This is
because talking to another application,
[across processes](http://en.wikipedia.org/wiki/Inter-process_communication),
is expensive and would be impractical to do for every notification
that is sent inside of an application. This makes a bit more difficult
to track down what notification is going to be sent through
accessibility; using notifications more difficult than simply using `#sleep`.

## Simple Example

Consider a log in window. You enter some credentials and then you
press a button to log in and load up the main application window.

This procedure is most likely asynchronous, it usually takes one or
two seconds, but could take longer. To script logging in you would
have to wait until the main application window loaded.

You could just use `Kernel#sleep`, but how long should you sleep for
and how reliable is that? How much time would that waste?

Notifications are perfect for this scenario; whenever a window is
created, the application sends out a notification to any accessibility
applications that are listening letting them know a window was created
and the notification will include the accessibility object and the
notification name. Using this system, we can just wait for the
notification to be received and continue executing the script right
away (technically, there can be a 1-2 ms delay). The code would look
like this:

     register_for_notification app, :window_created
     login # trigger an action that will eventually send a notification
     wait_for_notification

And that's it.

## One-Two Combo

Using notifications is a two step process: first a left jab to set up
the notification and then a right cross to wait for the
notification. If you're left handed then you can jab with the right
and cross with the left, but you still setup first and then wait...

### First You Set It Up

Setup is the important step and is fairly painless as far as what
you need to provide for AXElements. To register for a notification you
call {Accessibility::Language#register_for_notification}. You pass the
the {AX::Element} who will be sending the notification and then the
notification name. Another simple example would be:

    register_for_notification text_field, :value_changed

In this hypothetical case, we want to wait for a `:value_changed`
notification that will be sent by `text_field`. That's it. And that
also covers 90% of the cases where you will use notifications.

#### Applications Are Special

Listening from the application, an {AX::Application} object is a
special case. When you say that an {AX::Application} object will be
the sender, what you are saying is that any UI element in the app will
be the sender and you don't really care as long as you get the right
notification name (that's not entirely true, but a good enough lie for
now).

#### How Is Babby Formed?

Like attribute and action name translation, notification names are
also translated for your convenience. However, where do you get the
notification names that Apple provides?

It turns out that there is no API for getting a list of notifications
that an element can send---Apple dropped the ball in this case, but
they did provide a
[list of notifications](http://developer.apple.com/library/mac/#documentation/Accessibility/Reference/AccessibilityLowlevel/AXNotificationConstants_h/index.html).
The list of notifications is __required__ reading if you want to use
accessibility notifications.

For custom notifications, which I'll get to in a bit, you shouldn't
(read: don't) do a name translation unless you provide an equivalent
constant for the MacRuby run time. Instead, you should just provide
the string with the notification name:

    register_for_notification app, 'customNotification'

### Then You Wait

Technically, there is a step between where you trigger an action that
will cause the notification to be sent. Triggering actions is covered
in the {file:docs/Acting.markdown Acting tutorial}. Once you have
triggered the action, you simply need to wait for the notification:

    wait_for_notification

And then you wait. If all goes well you will receive the notification
and the script continues on to the next statement. By default,
AXElements will wait for 10 seconds, and if the notification is not
received then the script will continue anyways.

Waiting for longer, or less, time than the default can be done by
passing a parameter to `wait_for_notification`. For instance, you
could wait for a minute or a second:

    wait_for_notification 60.0
    wait_for_notification 1.0

## A Bit More Complicated

The above should cover most cases, but notifications can be more
complex than those examples. You might need to unregister for
notifications, or add more complex logic to a notification
registration.

### Unregister Notifications

If you need to unregister for a notifications then you can. The DSL
layer provides {Accessibility::Language#unregister_notifications_for}
and {Accessibility::Language#unregister_notifications}.

In the first case, you can unregister notifications for a specific
element, which must be the same element that you registered the
notification with, even if you registered with an application
object.

The DSL layer calls to the OO layer,
{AX::Element#unregister_notifications}, which in turn calls the core
layer, {AX.unregister_notifs_for}.

    unregister_notifications_for app # then calls
    app.uregister_notifications      # which then calls
    AX.unregister_notifs_for app

In the second case, you can unregister _all_ notifications. This is
actually done in cases where a notification is not received, simply to
clear out possible problems with lingering registrations that might
mess up future waiting. The DSL layer provides
{Accessibility::Language#unregister_notifications}, which directly
calls to the {AX.unregister_notifs}.

    unregister_notifications # then calls
    AX.unregister_notifs

### You Are The Decider

When you setup a notification you can optionally pass a block that
decides whether or not the received notification is the one you
wanted. You will be given the element that sent the notification, not
necessarily the element that you registered with, and the name of the
notification. In this case you would register for a notification like
so:

    register_for_notification app, :window_created do |window, notification|
      window.title == 'New Contact'
    end

This gives you some extra security. Instead of continuing the script
execution often getting the first `:window_created` notification, the
script will remain paused until the element that sends the
notification has a title of `'New Contact'`.

The contract is quite simple. If you do not pass a block, then the
first notification received will cause AXElements to stop waiting; if
you want to pass a block then the block must return Ruthy or falsey
to decide whether the received notification is the one that you
wanted. You will be given the sender of the notification as well as
the notification name; though the notification name will usually not
be very interesting since it is the value you registered with.

### More Than One Notification

You can register for as many notifications as you want, but I don't
recommend that you register for more than one at a time unless you
know what you are doing.

The reason why is that when you `wait_for_notification`, you are
pausing script execution until any of the notifications you have
registered for are received. The block that you pass will only be used
for notifications that are sent to the registration you set it up
with.

This is why if you fail to receive a notification, then AXElements
will unregister all existing notifications. This detail might also
screw you over if you are trying to work with more than one
notification at once.

### Rainbows And Unicorns

As mentioned earlier, accessibility notifications are not all rainbows
and unicorns. If you've played with notifications while going through
this tutorial then you may have noticed a problem or two with the
design.

#### Who Sends The Notification

Documentation is the only hint you really get about who will send
particular notifications. If you are confident that a certain
notification will be sent, but do not know who will be sending the
notification, then you can register with the {AX::Application} object
to be the sender of the notification. This causes you to receive
notifications from any object as long as it has the proper
notification type. If you use this feature in conjunction with passing
a block that always returns false, then you can capture all the
notifications for a period of time and find out who is sending the
notification. An example would look something like this:

    register_for_notification app, :value_changed do |element, notif|
      puts element.inspect
      false
    end

    # trigger some action

    wait_for_notification 30.0

Since you are returning `false` at the end of the block, the script
will pause until a timeout occurs and you will see the `#inspect`
output for each object that sends the notification.

### What Is Known To Work

- `:value_changed` is only sent by objects that have a `value`
  attribute, and should be sent every time that the value is changed,
  whether through accessibility or normal computer usage
- `:menu_opened` seems to only be sent by menu bar menus, not by menus
  opened by pop up buttons

### You Only Live Once

Notifications will only be received once. After they are sent, the
registration will be cancelled and you will not receive the
notification again unless you register again.

## Custom Notifications

Custom notifications are pretty simple. Apple recommends that you try
to use the built in notifications as much as possible, but
acknowledges that you may need to add your own notifications
sometimes.

As noted earlier, accessibility notifications use a different system
than cocoa notifications; accessibility notifications are much simpler
to send; it is simply a C function call with two parameters:

    NSAccessibilityPostNotification(self, @"Cheezburger");

The first parameter is the sender of the notification; just as with
other accessibility APIs from the server (read: app) side of things,
you pass the actual object and accessibility will create the token to
send to the client (read: AXElements). The one caveat in this case is
that the sender of the notification cannot be an object that is
ignored by accessibility or else the notification will not be sent. If
you are unsure whether or not the object is visible to accessibility,
then you need to call an extra function to find someone who _will_ be
visible to accessibility; these functions are listed in the
[AppKit Functions](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Miscellaneous/AppKit_Functions/Reference/reference.html#//apple_ref/doc/uid/TP40004154)
in the Accessibility section. An example would look like this:

    NSAccessibilityPostNotification(NSAccessibilityUnignoredAncestor(self), @"Cheezburger");

In this case you would be looking up the hierarchy for an ancestor,
but you could also look down the hierarchy for a descendant or to the
side for a sibling.

As a rule of thumb, if you end up spending more 20 minutes trying to
figure out which notification will should be listening for, and who
will be sending it, then you should just create a custom notification.
