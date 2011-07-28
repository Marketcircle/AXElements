# AXElements

AXElements is a DSL abstraction built on top of the Mac OS X
Accessibility and CGEvent APIs that allows code to be written in a
very natural and declarative style that describes user interactions.

The framework is optimized for writing tests that require automatic
GUI manipulation, whether it be finding controls on the screen,
typing, clicking, or other ways in which a user can interact with the
computer.

## Getting Started

Though it is not required, it would be beneficial to first read
Apple's
[Accessibility Overview](http://developer.apple.com/library/mac/#documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXModel/OSXAXmodel.html).

The entry point to using this framework is the accessibility object,
which is always descendant of the {AX::Element} class, such as the
{AX::Application} class.

There are a two ways to get a reference to an accessibility object:

* An point on the screen
  + Under the mouse
  + An arbitrary point
* An application object
  + Given a bundle identifier
  + Given an app name
  + Given a PID

The most common way to start is by creating a new object for an
application. I prefer to use the bundle identfier approach as it will
try to launch the application if it is not already running. An example
would look like this:

```ruby
Accessibility.application_with_bundle_identifier 'com.apple.mail'
```

## How To Proceed

With your foot in the door, there are many things you can do
now. The more common tasks will be to inspect the user interface and
to trigger actions such as a click or even simulate keyboard
input.

* {file:docs/Inspecting.markdown Inspecting}
* {file:docs/Acting.markdown Acting and other macros}
* {file:docs/MouseEvents.markdown Mouse manipulation}
* {file:docs/KeyboardEvents.markdown Keyboard manipulation}
* {file:docs/Searching.markdown Searching}
* {file:docs/Notifications.markdown Notifications}

## A Note About Caching

You need to be careful when you cache elements. When you trigger an
action you are changing the state of an application, and are likely to
invalidate some elements when they disappear (e.g. closing a
window). Trying to use an elment object when the UI it links to no
longer exists will crash MacRuby.

## Tools

When writing scripts, it is often faster to inspect the view hierarchy
using the Accessibility Inspector tool that is part of the Developer
Tools. The inspector will be located in
`/Developer/Applications/Utilities/Accessibility%20Tools/` once you
have the Developer Tools installed.
