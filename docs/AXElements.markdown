# AXElements

AXElements is a DSL abstraction built on top of the Mac OS X
Accessibility Framework that allows code to be written in a very
natural and declarative style that describes user interactions.

The framework is optimized for writing tests that require automatic
GUI manipulation, whether it be  finding controls on the screen,
typing, clicking, or the various other ways in which a user can
interact with the computer.


## Getting Started

Though it is not required, it would be beneficial to first read
Apple's
[Accessibility Overview](http://developer.apple.com/library/mac/#documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXModel/OSXAXmodel.html).

The entry point to using this framework is the accessibility object,
which is always descendant of the {AX::Element} class, such as the
{AX::Application} class.

There are a few ways to get a reference to an accessibility object:
* Start with a constant
* Create a new accessibility object representing an application
* Get the accessibility object at an arbitrary point on the screen
* Get the accessibility object under the mouse

![Class Diagram](images/AX.png)

The most common way to start is by creating a new object that
represents an application.

    AX::Application.application_with_bundle_identifier 'com.apple.mail'


## Concepts

The important thing to note from the previous section is the idea of
changing state and then verifying it.

## Mouse Stuff

All the different ways in which you can click on an object. See
[Mouse Events](./MouseEvents.markdown) for more detailed documentation
on how to manipulate the mouse.

## Tools

One of the most helpful tools for understanding the layout of the view
hierarchy is the
[Accessibility Inspector](file:///Developer/Applications/Utilities/Accessibility%20Tools/).
The inspector can be used to quickly understand the accessibility
layout of an app.

## Adding Accessibility To Your Own Apps

If you need/want to add accessibility to your own applications, you
will need to make sure you follow some simple rules:

* Constants need to have a namespace prefix that ends with AX (e.g. MCAX)
