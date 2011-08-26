# Actions (a.k.a. The Fun Part)

Actions are how you drive the user interface. They can be anything
from showing a menu to dragging a window, but are often simple things
like pressing a button. Most actions are subtly different cases
of the same thing, but it is important to understand the differences
and when to use different actions.

There are three types of actions, those provided by the accessibility
API as actions, those provided by accessibility APIs as keyboard
simulation, and those that are provided by the CGEvents API. In most
cases you can use at least two types of actions to achieve the desired
effect and each type of action has its own pros and cons to consider.

## Interface

Though there are three different APIs under the hood, they are exposed
through a common interface via the DSL methods in
{Accessibility::Language}.

    app = Accessibility.application_with_name 'Terminal'
    press app.main_window.minimize_button
    type "\\CMD+M", app
    click app.main_window.minimize_button

The above example demonstrates performing actions using the DSL
methods. The DSL methods are always some kind of action, such as
{Accessibility::Language#drag_mouse_to drag\_mouse\_to}, or
{Accessibility::Language#set_focus set\_focus} to name a few.

The point of the DSL is to put the actions at the front of statements
in order to separate verbs from nouns. In this way, scripts should
resemble instructions that you might give for reproduction steps in a
bug report---they should read like they were instructions for
a person. This style should make it easier to think about writing
scripts and it should also give better hints at when to refactor
code into helper methods like `log_in_as:with_password:`.

If you tried out the code snippet above you might notice the
difference between the APIs. In the first case, `press` was using the
actions provided by the accessibility APIs to call the press action on
the minimize button for the window, in the second case we used `type`
to type in the hot key for minimizing a window, and in the third case
we used `click` from the CGEvents APIs to actually move the mouse
cursor to the button and generate a click event.

## Accessibility Actions

Actions like `press` use the accessibility APIs and show up in the
list of actions returned by {AX::Element#actions}. These actions will
also show up in the Accessibility Inspector in the Actions section.

You may have noticed that {Accessibility::Language#press `#press`}
shows up as `AXPress` for buttons when you view them with the
Accessibility Inspector or by calling {AX::Element#actions}. This is
because we do name translation with accessibility actions just like
when accessing attributes as shown in the
{file:docs/Inspecting.markdown Inspection tutorial}.

Accessibility actions are the simplest and fastest way to trigger
actions. They use the accessibility APIs to talk directly to the
application to call the same methods that would be called when
you interact with the application with the mouse or keyboard, but
without having to use the mouse or keyboard.

## Adding Accessibility Actions

If you have access to the source code for an app, you can add more
accessibility actions. You need to override two methods, just like
with adding attributes:

– `accessibilityActionNames`
– `accessibilityPerformAction:`

These methods should be implemented in the same way that you would
implement new attributes, just as detailed in the
{file:docs/Inspecting.markdown Inspecting tutorial}. The one
difference is that `accessibilityPerformAction:` should not return
anything after it performs the action.

### You Want To Use Actions

The advantage to using accessibility actions is that they are usually
much easier to use than the other APIs. Accessibility actions are
usually synchronous and so your scripts will not need to worry about
waiting for animations to complete. The only complication is that
sometimes an action is not synchronous, and there is no good way to
tell if an action is synchronous without looking at the underlying
code.

### Asynchronous Problems

Problems with synchronous behaviour will occur with all the types of
actions, but less often with accessibility actions, so you should
always try thing out first in the console to make sure.

A good rule of thumb is that anything that looks like it would take a
noticeable amount of time, and is not an animation, will probably be
asynchronous. An example of this would be having to load data from
a database (read: separate process, across a network, etc.) such as in
the Marketcircle server admin apps or the Billings Pro preferences.

Asynchronous behaviour can often be worked around by using
accessibility  {file:docs/Notifications.markdown notifications} or by
simply calling
[`#sleep`](http://rdoc.info/stdlib/core/1.9.2/Kernel#sleep-instance_method).
Notifications have some interesting caveats that are covered in their
own tutorial and so it is much easier to `sleep`.

However, using `sleep` to solve the problem of asynchronous waiting is
like using a steak knife for surgery when you wanted a scalpel. Unless
you can control the environment when the script is running, you will
need to sleep for longer periods of time than you really need to; even
when you have quite a bit of control you might still have the
occasional instance where a database fetch takes longer than
expected. I would suggest you use notifications when you can, and
sleep when you cannot.

## CGEvents Actions

CGEvents based actions never directly use the accessibility APIs and
are implemented at a different level of the GUI stack in OS X (I
assume). An action that uses CGEvents will actually move the mouse
cursor around and simulate mouse input at a fairly low level of
abstraction, which is why it is separate from accessibility, but it
will use accessibility information to find the point on the screen to
move to and click. These types of actions are more realistic, more
awesome looking, and also more difficult to write.

The difficulty in writing the scripts comes from the fact that it does
not directly communicate with the accessibility APIs. This implicitly
means that all CGEvents actions are asynchronous, which is the only
real complication with using CGEvents APIs.

### CGEvents Goes Where Accessibility Cannot

The benefit of actually moving the mouse will often outweigh the
downside here. Moving the mouse cursor and generating click events
allows things like dragging and scrolling which cannot be done using
the accessibility APIs.

As mentioned earlier, CGEvents doesn't talk to applications in the
same way that accessibility APIs do, which means that you can use
CGEvents actions on UI elements that do not fully support
accessibility. For instance, text might appear on the UI and have a
click-able link but may not provide an equivalent action to clicking on
the link; using CGEvents APIs you will only need to move to the
position of the text and then generate a click event.

### Realism

Since CGEvents actually manipulates the mouse cursor, any script that
uses the APIs will be more realistic than their equivalent
accessibility actions. This can make a difference if you are testing
an app and you are expecting other side effects to occur. For instance,
what if you implemented a sort of UI element that requires the mouse
cursor to be near the element for an action to trigger, such as an
expanding drawer or a folder in the finder. Depending on what you are
using AXElements for, this may or may not be important to you.

### Underpinnings

An important thing to note is that AXElements always works with
flipped co-ordinates. The origin, `(0, 0)` is always located in the
top left corner of the main display. Displays to the left have a
negative `x` co-ordinate and displays above the main display will have
negative `y` co-ordinates.

Though the CGEvents APIs are exposed to AXElements through the
{Accessibility::Language Language} module, there is another thin
layer between AXElements and CGEvents that abstracts everything that
AXElements uses.

The in between layer is the {Mouse} module, and it is responsible for
generating events and animating the mouse movements on screen. The API
that is makes available to AXElements is more fine grained than what
AXElements makes available to you. There is a lot of room for the
{Mouse} module to grow and add new features, some of which are noted
as `@todo` items in the documentation. It may also be necessary in
the future to make available from AXElements certain options that are
normally hidden in {Mouse}.

### Where The Mouse Moves

Consider the following:

    move_mouse_to app.main_window.close_button

If you try out that code snippet then you will notice that the mouse
cursor not only moves to the button, but the center of the button. If
you use the method to move to another object, such as a button, you
will again notice that it moved to the center point of the element
(with a few exceptions).

You can call `move_mouse_to` and give it a UI element, but you could
also be more exact and give it a CGPoint or even an array with two
numbers. In fact, you could pass just any object as long it implements
a method named `#to_point` which returns a CGPoint object. If you were
to look at the code for {Accessibility::Language#move_mouse_to} you
would see that all it does is call `#to_point` on the argument and
then pass the returned value to the {Mouse} module to actually do the
work. That's
[confident code](http://confreaks.net/videos/614-cascadiaruby2011-confident-code)!

You could also look at {NSArray#to_point} and find out that it just
returns a new CGPoint using the first two objects in the array, and
`CGPoint#to_point` just returns itself (you can't see the
documentation for the method because of how it is
implemented). Similarly, {AXElement} implements
{AXElement#to_point `#to_point`} which not only gets the position
for the element, but also gets the size and then calculates the center
point for the element. This is important because you probably never
want the mouse cursor moving to the top left of the UI element, but
maybe you don't the cursor moving to the center either.

If you want to have the mouse move to a location over a UI element
that is not the center point, then you will need to implement
`#to_point` for the appropriate class. Just remember to follow the
{file:docs/NewBehaviour.markdown rules} for choosing the proper
superclasss. For instance, on Snow Leopard you could resize a window
by clicking and dragging an `AX::GrowArea` object in the lower right
corner of a window; moving to the center of the element may not
actually allow the mouse to respond and so you would have to implement
`#to_point` to move closer to the bottom right of the window
(__NOTE__: I don't know if that is actually true for `AX::GrowArea`,
it was just meant as an example).

### Dragging

Sometimes you just need to be able to click and drag an element. To do
this you can only use the CGEvents APIs. Fortunately, click and drag
is relatively painless with AXElements, the simplest example would be
something like this:

    # move to the mouse to the starting point
    move_mouse_to app.main_window.title_ui_element

    # start the click and drag event
    drag_mouse_to [0, 0]

Pretty cool, eh? The general pattern is to move the mouse to the
starting point, and then to call `drag_mouse_to` to start the click
and drag events. In the example I gave co-ordinates using an array
with two numbers but you can pass a CGPoint or anything else that
responds to `#to_point` just like with the other CGEvents actions.

## Keyboard Actions

There final type of action is the keyboard action. Keyboard actions
live in a world between the accessibility APIs and CGEvent APIs; that
is, Apple has already done the work of unifying them for me and in a
way that I would not have been able to do myself.

The keyboard action is a single method,
{Accessibility::Language#type}, that requires one parameter and
takes an optional second parameter. The first parameter is simply a
string that includes which characters you wish to have typed out and
the second parameter is the UI element for the application where you
would like to send the keyboard events. Since the second parameter is
optional, if you do not provide it then the keyboard events will be
sent to which ever app currently has focus.

    # to a specific app
    app = Accessibility.application_with_name 'Terminal'
    type "Hello, world!", app

    # to the focused app
    type "Hello, world!"

The string that you pass can have some special escape sequences to
indicate that you want to press command characters or a combination of
keys at once for a hot key. Details on this are contained in their own
tutorial, the
{file:docs/KeyboardEvents.markdown Keyboard Events Tutorial}.

## Mixing In

By now you will have noticed that all the actions have been defined in
the {Accessibility::Language} name space, which is just a simple
module. Though, you have been able to use the methods anywhere and in
any context.

When you load AXElements, by using `require 'ax_elements'`, not only
will all the code be loaded, but the extra step of mixing
{Accessibility::Language} into the top level name space will also be
done for you. The only way to override this behaviour is to load the
components of AXElements yourself, the details on how to do this are
left as an exercise to interested parties.
