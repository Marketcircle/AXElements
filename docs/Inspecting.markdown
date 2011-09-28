# Inspecting The User Interface

When it comes to inspecting the user interface there are _many_ nooks
and crannies that are interesting to talk about. This document covers
the core concepts that you will need to understand before you can
begin discovering them yourself.

## The UI Tree

The first most important thing to understand is that accessibility
exposes the user interface as a hierarchy of user interface
tokens. Each token references a GUI element on screen, either
something literal like a button, or something more structural like a
group of buttons. For simplicity, I will refer to tokens as if they were the
objects themselves.

Each object knows who its parent object is, and knows about any
children objects that it may have. thus creating a tree structure. At
least this is the theory, but there are, on occasion, some hiccups
since accessibility is a protocol to which multiple parties have to
conform.

A sample hierarchy might start with the application, which has a menu
bar as one of its children and the menu bar has menu bar items, each
menu bar item has a menu and each menu has menu items; some menu items
have another menu as its child which then leads to more menu items and
so on. This hierarchy is much easier to understand once visualized:

![Example GUI Hierarchy](images/ui_hierarchy.png)

This example is meant to be instructive, the menu bar is one of the
more complicated hierarchies to navigate and many other nodes in the
hierarchy have been left out. The good news is that AXElements has
techniques and patterns for simplifying navigation, so don't get
scared off just yet. The point here is that each menu item knows which
menu is its parent, and each menu knows which menu item or menu bar
item is its parent, and the menu bar knows that which application is
its parent. But who is the parent of the application? It turns out
that that is a trick question, an application does not have a
parent. An application is the entry point for the UI hierarchy, it
will be the place where a script usually starts and application
objects can be created using the {Accessibility} singleton
methods. You can create the object for an application that is already
running using {Accessibility.application_with_name} like so:

    app = Accessibility.application_with_name = 'Finder'

### Accessibility Inspector

To quickly navigate through the UI tree, Apple has provided a tool,
the Accessibility Inspector, as part of the Developer Tools. The
inspector will come in handy when you are writing scripts using
AXElements, though there are some potential pitfalls that will be
discussed later.

Once you install the Developer Tools, the inspector can be found in
`/Developer/Applications/Utilities/Accessibility Tools/`. It is worth
playing around with the inspector to get a feel for what the
accessibility APIs offer; but keep in mind that the inspector is a
dumb interface to the accessibility APIs.

## Attributes

Each item in the GUI tree has attributes; buttons have a title,
sliders have a value, etc.. Pointers to the parent and chilrden nodes
are also attributes. Programmatically, you can get a list of
attributes that an object has by asking nicely. AXElements exposes
this API via {AX::Element#attributes}. {AX::Element} actually acts as
the abstract base class for all objects, encapsulating everything that
the accessibility APIs offer.

### Accessing Attributes

Every attribute can be accessed as a method of the UI object. The
method name will always be the
[snake_case](http://en.wikipedia.org/wiki/Letter_case) version of the
attribute name without the prefix.

Some examples:

- `AXChildren` would become `children`
- `AXMainWindow` would become `main_window`
- `AXIsApplicationRunning` would become `application_running?`

The last case is special because we consider "`Is`" to be part of the
prefix and the method name has a "`?`" at the end. This is to follow
Ruby conventions of putting "`?`" at the end of the method name if the
method is a predicate. There will be more details about these rules in
other tutorial documents, but this is really something that should be
abstracted away. This detail is not hidden right now becaues the
Accessibility Inspector does not hide the information and you still
need to understand it in order to use the inspector with AXElements.

#### Example

We can demonstrate how this all comes together with a small
example. In the terminal, you can start up a console session of
AXElements by loading `ax_elements` in `macirb` or by navigating to
the AXElements repository and running the `console` task if you have a
clone. Then you can try the following code, one line at a time:

    app    = Accessibility.application_with_name 'Terminal'
    window = app.main_window
    title  = window.title
    puts "The window's title is '#{title}'"

In the first line, we are creating the object for the application. As
mentioned earlier, you will usually start navigating the UI tree from
the application object. Giving the name of the application is the
easiest way to create an application object but requires the
application to already be running.

On the second line we use the application object and ask it for the
value of the `main_window` attribute. This will return to us another
UI object, this time for the window. You will also notice that the
console printed out some extra information about the window, such as
the title of the window and its position (in flipped
coordinates). Each UI element has implemented the `#inspect` method in
such a way as to provide users with a succinct but useful way to
identify the UI element on the screen, and `macirb` is designed to
happily print that information out for each statement that you enter.

On the third line, we ask the window for it's `title`, and it gives
us back a string which we then print out on the fourth line. Notice
that the title of the window was also printed by the console as part
of the `#inspect` output that `macirb` asks to print out.

### Inspect Output

Using `#inspect` is a great way to see the important details of a UI
element, it shows the values of the most important attributes so that
you can quickly identify which element it really is on screen, but not
so many details that it becomes a pain. A typical example of
`#inspect` output looks like this:

    #<AX::StandardWindow "AXElementsTester" (1584.0, 184.0) 17 children focused[✘]>

That output includes all the pieces that you will normally see from
`#inspect`, but you may see less or more depending on the UI element
that is being inspected. As is the norm in Ruby, you will always at
least get the name of the class; then AXElements will try to include a
piece of identifying information such as the `title`, then you have
numbers in parentheses which are the screen coordinates for the
object, then you have the number of children, and then check boxes for
boolean attributes. Aside from the class name, the other pieces of
information will only be included if they are relevant, and certain
objects will also include other information.

The values shown by `#inspect` are pieced together using helper
methods from the {Accessibility::PPInspector} module. {AX::Element}
implements a generic implementation with
{AX::Element#inspect}. However, the generic `#inspect` may not always
choose the best attributes to show. An example would be
{AX::Application#inspect}, which overrides the generic `inspect` so
that the process identifier for the application is also included. In
other cases, the screen co-ordinates or whether the element is enabled
may not be relevant, so you can override the method in the specific
subclass to not include those attributes and/or include other
attributes. The key idea is to make `#inspect` helpful when exploring
a UI through the console or when debugging a script.

## Accessing Children

Following first principles shown in the example from above you might
be led to believe that in order to navigate around the UI tree you
will have to write code that looks something like this:

    app.main_window.children.find do |child|
      child.class == AX::Button && child.title == 'Add'
    end

However, AXElements provides a way to specify what you want that is
much more convenient to use. Behold:

    app.main_window.button(title: 'Add')

This is quite the simplification! If we break it down, you see that
the method name is the class of the object you want, and then if you
need to be more specific you can pass key-value pairs where the key
is an attribute and the value is the expected value. The above example
says "find a button with the title of 'Add'".

You can use as many or as few key-value pairs as you need in order to
find the element that you are looking for. If you do not specify any
key-value pairs, then the first object with the correct class will be
chosen. The {file:docs/Searching.markdown Searching Tutorial} goes
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
is so trivial in Ruby (but this parameterized attribute actually exists).

Parameterized attributes are different enough from regular attributes
that Apple does not want them mixing together and producing
offspring. AXElements is a bit progressive, but still keeps the list
of parameterized attributes separate from attributes; you can get a
list of parameterized attributes for an object with
{AX::Element#param_attributes}. Similarly, you have probably already
noticed that parameterized attributes have their own section in the
Accessibility Inspector and that many objectss do not have any
parameterized attributes.

In my experience, parameterized attributes have not been very useful,
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

    app.param_attribute(:string_for_range, CFRange.new(0,5))

These methods are exposed so that other library classes can achieve
better performance; but you should avoid using them regularly. These
APIs may be hidden in the future in order to enforce the DSL usage.

## Adding Accessibility Attributes

You can add custom attributes to objects, or even inject or hide
objects from the UI hierarchy. It is simply a matter of
overriding/implementing methods from the
[NSAccessibility](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Protocols/NSAccessibility_Protocol/Reference/Reference.html)
protocol where needed.

You should peruse the {file:docs/AccessibilityTips.markdown Accessibility Tips}
documentation before making nontrivial changes. There are a couple of
guidelines you need to be aware of in order to make sure things remain
compatible with AXElements.

## Next Steps

You may want to play with what you have learnt so far, see if you can
find bugs and then fix them, or perhaps add missing features. ;)

From here the next logical step would be to figure out how to trigger
some sort of action and then inspect the UI for changes; for that
topic you should read the {file:docs/Acting.markdown Acting Tutorial}.
