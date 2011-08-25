# Inspecting The User Interface

When it comes to inspecting the user interface there are _many_ nooks
and crannies that are interesting to talk about. This document covers
the core concepts that you will need to first understand.

## The UI Tree

The first most important thing to understand is that accessibility
exposes the user interface as a hierarchy of user interface
objects. Each object knows who its parent is, and knows about any
children that it may have, thus creating a tree structure.

For instance, an application has a menu bar and the menu bar has menu
bar items, each menu bar item has a menu and each menu has menu
items, and some menu items have a sub menu which leads to more menu
items, and so on. Each menu item knows which menu is its parent, and
each menu know which menu item or menu bar item is its parent, and the
menu bar knows that which application is its parent.

But who is the parent of the application? The answer is that an
application does not have a parent, it is the entry point for a UI
hierarchy, and the place where a script will usually start.

### Accessibility Inspector

To quickly navigate through the UI tree Apple has provided a tool, the
Accessibility Inspector, as part of the Developer Tools. The inspector
will come in handy when you are writing scripts using AXElements,
though there are some potential pitfalls that will be discussed later.

Once you install the Developer Tools, the inspector can be found in
`/Developer/Applications/Utilities/Accessibility Tools/`, or just use
the launchpad if you are on OS X Lion.

## Attributes

Each item in the tree has attributes; buttons have a title, sliders
have a value, etc.. Attributes often include pointers to the parent of
the element and, if applicable, a pointer to an array of children;
this is how you navigate through the UI tree.

Programmatically, you can get a list of attributes that a UI element
has by asking the element for its {AX::Element#attributes}.

### Accessing Attributes

Every attribute can be accessed as a method of the UI element
object. The method name will always be the
[snake_case](http://en.wikipedia.org/wiki/Letter_case) version of
the attribute name without the prefix.

Some examples:

- `AXChildren` would become `children`
- `AXMainWindow` would become `main_window`
- `AXIsApplicationRunning` would become `application_running?`

The last case is special because we consider "`Is`" to be part of the
prefix and the method name has a "`?`" at the end. This is to follow
Ruby conventions of putting "`?`" at the end of the method name if the
method is a predicate. There will be more details about these rules in
other tutorial documents.

#### Example

We can demonstrate how this all comes together with a small
example. In the terminal, navigate to the AXElements repository and
start a console session with `macrake console`. Then you can try the
following code, one line at a time:

    app    = Accessibility.application_with_name 'Terminal'
    window = app.main_window
    title  = window.title
    puts "The window's title is #{title}"

In the first line, we are creating the UI element object for the
application. As mentioned earlier, you will usually start navigating
the UI tree from the application object. Giving the name of the
application is one of the few ways that AXElements supports creating
an application object; other methods of creating applications are
covered in other tutorial documents, but using the name is the
easiest.

On the second line we use the application object and ask it for the
value of the `main_window` attribute. This will return to us another
UI element object, this time for the window. You will also notice that
the console printed out some extra information about the window, such
as the title of the window and its position (in flipped
coordinates). Each UI element has implemented the `#inspect` method in
such a way as to provide users with a succinct but useful way to
identify the UI element on the screen, and `macirb` is designed to happily
print that information out for each statement that you enter.

On the third line, we ask the window for it's `#title`, and it gives
us back a string which we then print out on the fourth line. Notice
that the title of the window was also printed by the console as part
of the `#inspect` output that it prints out.

### Inspect Output

Using `#inspect` is a great way to see the important details of a UI
element, it shows the values of the most important attributes so that
you can quickly identify which element it really is on screen, but not
so many details that it becomes a pain. A typical example of
`#inspect` output looks like this:

    #<AX::StandardWindow "AXElementsTester" (1584.0, 184.0) 17 children focused[✘]>

That output includes all the pieces that you will normally see from
`#inspect`, but you may see less or more depending on the UI element
that is being inspected. First you have the class name so that you can
tell what kind of UI element it is; then you have some sort of
identifying information bit, which is the title of the window in this
case; then you have numbers in parentheses which are the screen
coordinates for the UI element; then you have the number of children
that the UI element has, but only because this element has children;
and finally you have a check box for the `focused` attribute.

The values shown in `#inspect` are pieced together using helper
methods from the {Accessibility::PPInspector} module and a generic
implementation is written in {AX::Element#inspect} so that all UI
elements have a useful `#inspect`. However, the generic `#inspect` may
not always choose the best attributes to show.

{AX::Application#inspect} overrides the generic `Object#inspect` so
that the process identifier for the application is also included. In
other cases, the screen co-ordinates or whether the element is enabled
may not be relevant, so you can override the method in the specific
subclass to not include those attributes and/or include other
attributes. The key idea is to make `#inspect` helpful when exploring
a UI through the console or debugging a script.

## Accessing Children

Following first principles shown in the example from above you might
be led to believe that in order to navigate around the UI tree you
will have to write code that looks something like

    app.main_window.children.find do |child|
      child.role == AX::Button && child.title == 'Add'
    end

in order to find a specific child element. However, AXElements
provides a way to specify what you want that is much more convenient
to use. Behold

    app.main_window.button(title: 'Add')

which is quite the simplification! If we break it down, you see that
the method name is the class of the object you want, and then if you
need to be more specific you can pass a key-value pair where the key
is an attribute and the value is the expected value. The above example
says "find a button with the title of 'Add'".

You can use as many or as few key-value pairs as you need in order to
find the UI element that you are looking for. If you do not specify
any key-value pairs, then the first object with the correct class will
be chosen. The {file:docs/Searching.markdown Searching Tutorial} goes
into more depth on how key-value pairs are used to specify which
object you want.

## Parameterized Attributes

There is a special type of attribute that is called the parameterized
attribute. The difference from a regular attribute is that you need to
supply a parameter. An example of this would look like this:

     static_text.string_for_range CFRange.new(0,5)

The method name suggests that you need to provide a range and in
return you will be given part of the string that corresponds to the
range. Of course, this example is quite contrived since string slicing
is so trivial in ruby (but the parameterized attribute actually exists).

Parameterized attributes are different enough from regular attributes
that Apple does not want them mixing together and producing
offspring. AXElements is a bit progressive, but still keeps the list
of parameterized attributes separate from attributes; you can get a
list of parameterized attributes for an object with
{AX::Element#param_attributes}. Similarly, you have probably already
noticed that parameterized attributes have their own section in the
Accessibility Inspector, but not all UI elements have parameterized
attributes.

In my experience, parameterized attributes have not been that useful,
but I haven't looked hard enough and am still looking for a good
example to put in this section of the tutorial.

## Explicit Attribute Access

In cases where you know what you want is going to be an attribute, you
can get better performance from accessing attributes by calling
{AX::Element#attribute} and passing the attribute name.

    app.attribute(:main_window)

Similarly, for parameterized attributes, you need to call
{AX::Element#param_attribute} and pass the attribute name and
parameter as parameters to that method.

## Adding Accessibility Attributes

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

## Next Steps

You may want to play with what you have learnt so far. See if you can
find bugs and then fix them, or perhaps a missing feature.

From here the next logical step would be to figure out how to trigger
some sort of action and then inspect the UI for changes; for that
topic you should read the {file:docs/Acting.markdown Acting Tutorial}.
