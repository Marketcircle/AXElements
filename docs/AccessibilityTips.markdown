# Accessibility Tips

This document includes tips for customizing accessibility in your own
applications. The goal is to inform you of pitfalls that are not
mentioned in Apple's documentation. It also includes notes on how to
avoid making decsions that will make an application incompatible with
AXElements.

@todo This document is under construction and is currently just a set
of notes and unorganized sections ripped from other documents.

## Guidelines

When implementing custom accessibility roles, you should never use a
pluralized name for the role. A role that is already pluralized will
break search.


## Adding new stuff

Adding new attributes to an object is very simple...usually. Most of
the time it is as simple as overriding two methods:

- `accessibilityAttributeNames`
- `accessibilityAttributeValue:`

`accessibilityAttributeNames` needs to return an array with the names
of available attributes. You should call `super` to get the existing
array first, and then append any custom attributes you want to
provide.

An attribute name must follow the convention of being a camel cased
string with the "AX" prefix, such as `AXTitle`. You can optionally
include an additional prefix before "AX", such as "MCAX" for
Marketcircle custom attributes. If you do not follow these rules then
attribute names will not be translated properly by AXElements.

`accessibilityAttributeValue:` is how you actually provide the value
for the attribute; the parameter for this method is the name of the
attribute fetched from calling `accessibilityAttributeNames`. You
should return the value without doing any extra work to the data; the
Accessibility interface will do any wrapping or translating for
you (e.g. CGPoint objects will have co-ordinates flipped). In the case
of a C structs you should leave them wrapped in an NSValue object.

Similarly, parameterized attributes are added using methods with
`Parameter` in the name. The method for getting the value of a
parameterized attribute will of course take an extra parameter for the
parameterized attributes parameter.

### Where To Implement The Methods

The difficulty in adding attributes lies in finding out where you need
to add the accessibility methods. Often, the class that implements
accessibility is the class that draws the user interface element. For
example, the accessibility information for a button is implemented on
the button cell and not the button itself. Since Apple is under the
delusion that you will never need to add any custom accessibility
information, they really don't document these customizations enough,
and so this document only includes caveats that have been discovered
so far.

It is often inconvenient to subclass the cell for an object just for
accessibility. In these cases Apple has provided something similar to
singleton methods, but less useful, with the
`accessibilitySetOverrideValue:forAttribute:` method. You can use the
method to override an attribute or even add a new one. The main issue
with this method is that any attribute that is overridden, or added,
will not be writable using the accessibility APIs. Another issue is
that you have to calculate the value when you override instead of when
the attribute value is queried by the client.

### Writability

In the case where it is convenient to be able to change an attribute's
value through accessibility, like the size of a window, you will also
need to implement two more methods for the attribute:

- `accessibilityIsAttributeSettable:`
- `accessibilitySetValue:forAttribute:`

`accessibilityIsAttributeSettable:` simply responds with whether or
not the attribute is writable, and
`accessibilitySetValue:forAttribute:` will be called to actually write
to the attribute.

### Remember `super`

It is important to remember that these methods are already implemented
for the built in features. When overriding, you should only implement
the custom behaviour and call `super` to handle everything else.

### Existing Definitions

When implementing custom behaviour, you should try and use
pseudoclasses that have already been defined by Apple, as well as
attributes, parameterized attributes, and other features that have
already been defined. Apple maintains the documentation for all their
definitions on
[here](http://developer.apple.com/library/mac/#documentation/UserExperience/Reference/Accessibility_RoleAttribute_Ref/Introduction.html#//apple_ref/doc/uid/TP40007870).
The documentation is fairly detailed now (moreso than before), but
still misses a few things.


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

