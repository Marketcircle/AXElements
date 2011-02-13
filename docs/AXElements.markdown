AXElements
===================

AXElements is an abstraction layer on top of the Mac OS X
Accessibility Framework that makes it behave in an object oriented
manner.

The framework is optimized for writing tests that require some level
of automatic GUI manipulation, whether it be  finding controls on the
screen, typing, clicking, or the various other ways in which a user
can interact with the computer.

Getting Started
===============

The entry point to using this framework is the accessibility object,
which is a descendant of the {AX::Element} class, such as the
{AX::Application} class.
The first thing you need to do is get a reference to the existing

![Class Diagram](images/AX.png)

Tools
=====

One of the most helpful tools for understanding the layout of the view
hierarchy is the
[Accessibility Inspector](file:///Developer/Applications/Utilities/Accessibility%20Tools/).
The inspector can be used to quickly understand the accessibility
layout of an app.
