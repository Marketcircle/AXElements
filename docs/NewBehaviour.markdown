# Adding Behaviour

Sometimes it is necessary to add extra methods to a UI
element. There are a few cases of this in the AXElements source code
itself, but many more opportunities exist.

Unfortunately, extending UI element classes in AXElements is not
totally straightforward. Some of the implementation details need to be
understood before you can successfully extend AXElements.

## Laziness

In a laziness contest between AXElements and Garfield, AXElements wins
8 times out of 10. A lot of data that AXElements needs to be
processed, such as name translation, and the work for this is delayed
until it needs to be done. Well, that's not quite true but it is close
enough to the truth.

## Class Hierarchy

At run time you will have notice that you were returned objects which
have a class like `AX::StandardWindow`, but you can never find the
definition of the class in the source code. This is because the class
hierarchy is lazily defined.

### Deciding The Class Name

The first thing to understand is the way that AXElements decides what
class to instantiate for a UI element. This is actually pretty
simple. Each UI element has a `role` attribute that is supposed to be
used by assistive applications (read: AXElements) to understand which
attributes will likely be available. This is Apple's hint as to what
kind of class structure to choose.

However, some UI elements also have a `subrole` attribute. For
instance, `AXStandardWindow` is a subrole attribute that a UI element
can have if it has a `role` of `AXWindow`. Once again, this is a hint
that has been built into the system, and AXElements follows these
hints. Put into object-oriented terms, if an object has a `subrole`,
then that `subrole` becomes the class for the object and the `role`
becomes the superclass; if the object does not have a `subrole`, then
the class of the object will be decided by the `role`.

### Abstract Base

In either case, the {AX::Element} class will be an ancestor for the
class that is chosen. A class that is `subrole` will always have a
superclass that is a `role`, and a class that is a `role` will always
have {AX::Element} as its superclass.

The advantage to creating this hierarchy is that it becomes much
easier to implement searches that can find a "kind of" object. For
instance, you can search for `text_fields` and find `AX::TextField`
objects as well as `AX::SecureTextField` objects. This is one of the
more powerful features outlined in the
{file:docs/Searching.markdown Searching tutorial}.

### Why Lazy?

Laziness was chosen as it makes the library more resilient to custom
roles and subroles. However, it also allows the MacRuby run time to
boot faster since it avoids having to load all the different classes
that would need to be defined.

## Explicitly Defining Classes

Now that you understand how classes are structured it should be very
obvious how you should name your classes and choose your superclass.

However, you could also use this technique to customize the hierarchy
from what Apple has defined. For instance, you could force a
`AXPopUpButton` to be a subclass of `AXButton` even though Apple has
declared them to be separate roles. This may or may not be convenient
depending on what custom methods you wish to add.

## Reasons To Add A Custom Method

For this topic I can only lead by example. Fortunately AXElements has
a few examples to show off. The full list is in
`lib/ax_elements/elements`, but I'll go over a few here.

### Application Objects

{AX::Application} has been extended in a couple of ways. First off, in
order to provide an object oriented interface to sending keyboard
events I added {AX::Application#type}.

The big change with {AX::Application} is the merging of functionality
from `NSRunningApplication`. In order to provide methods to set focus
to an application I actually had to cache the `NSRunningApplication`
instance at initialization and forward some method calls to that
object. For instance, when you call `#set_focus` and pass an
application object, AXElements does not actually using accessibility
to set focus to the application, it uses the `NSRunningApplication`
class internally still support the functionality in a transparent way.

### Overriding `#==`

The most popular customization to make is to overload `#==` for an
object class that provides a more natural interface, and also one that
makes search much more flexible.

There is more than one example in this case, you could look at
{AX::StaticText#==} which allows you check equality against a string
that equal to the `value` attribute for the static text
object. Similarly, {AX::Button#==} was added to check equality with
buttons.

### Table Rows

When working with `AX::Table` objects you may have issues identifying
children that belong to a specific column. Children of table rows, in
my experience, do not have descriptions identifying which column they
belong to. In cases where you have no relatively unique identifier for
a child, such as multiple check boxes, there is no good way to find a
specific check box using the built in search mechanics.

You could hope that the column order never changes and just use the
index of the children array but that is fragile. Perhaps you actually
know what the order of the columns is to begin with and were able to
keep track of how they changed, but I am not sure that that is even
possible to do with the accessibility APIs.

Though, the likeliest scenario is that the only sane way to identify
the child is by identifying the column that the child belongs to. For
instance, a the column for a table is an `AX::Column` object that
usually has a `header` or `title` attribute which will be unique for
the table. For this case, I have added the {AX::Row#child_in_column}
method which provides something similar to a search but with the few
extra steps that would be necessary to correlate the child to the
column and then return the child that you wanted.
