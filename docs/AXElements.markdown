# AXElements

AXElements is a DSL abstraction built on top of the Mac OS X
Accessibility and CGEvent APIs that allows code to be written in a
very natural and declarative style that describes user interactions.

The framework is optimized for writing tests that require automatic
GUI manipulation, whether it be finding controls on the screen,
typing, clicking, or other ways in which a user can interact with the
computer.

## Getting Started

Though it is not required, you should read Apple's
[Accessibility Overview](http://developer.apple.com/library/mac/#documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXModel/OSXAXmodel.html)
as a primer on the technical underpinnings of AXElements.

Users of AXElements would be best off reading through the tutorials
providied in the documentation, starting with the
{file:docs/Inspecting.markdown Inspecting Tutorial}.

## How To Proceed

Once you have an understanding of the basics, you can peruse the other
tutorials to get and in-depth understanding of how AXElements works
and how to use it.

* {file:docs/Inspecting.markdown Inspecting}
* {file:docs/Acting.markdown Acting and other macros}
* {file:docs/KeyboardEvents.markdown Keyboard manipulation}
* {file:docs/Searching.markdown Searching}
* {file:docs/Notifications.markdown Notifications}
* {file:docs/Debugging.markdown Debugging Problems}
* {file:docs/NewBehaviour.markdown Adding Behaviour}
* {file:docs/RSpecMinitest.markdown RSpec and Minitest extensions}

## A Note About Caching

You need to be careful when you cache elements. When you trigger an
action you are changing the state of an application, and are likely to
invalidate some elements when they disappear (e.g. closing a
window). Trying to use an elment object when the UI it links to no
longer exists will crash MacRuby.
