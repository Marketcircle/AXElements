# Searching

Searching the view hierarchy is the most powerful idea that this
toolkit provides by _significantly_ simplifying the process of
describing UI elements.

Search works by looking at the child elements of the current element,
and possibily at the grandchildren, and so on and so forth in a
breadth first search through the UI hierarchy rooted at the current
node.

There are a few well defined features of searching that make it
powerful: pluralization, attribute filtering, nesting, and element
attribute inference.

## Search Basics

First, the basic form of a search looks like this:

```ruby
$ELEMENT.$KLASS($FILTER_ATTRIBUTE1: $FILTER_VALUE1, ...)
```

Actually, that is just the form for an implicit search, which is a
little nicer to write than an explicit search. The only difference
between the two is that an implicit search must always find something
or else a {AX::Element::SearchFailure} error will be raised.

Looking at the pieces of the statement, the obvious piece is
`$ELEMENT`; `$ELEMENT` is the element to start searching from. Then
`$KLASS`, the method name, is the class of the object to search for,
and the parameter list is just a hash where the key,
`$FILTER_ATTRIBUTE`, is an attribute on the instance of the class and
the value, `$FILTER_VALUE`, needs to match what is returned when the
attribute is looked up.

An implicit search is written as if the class of the object you were
searching for was the method and the filters would be the parameters
for the method. If we substitute real values in, an example would like
this:

```ruby
window.button(title: 'Main Window')
```

Meaning that we want to find a `button` that is a child (or descedant)
of `window`, but only if the `button` has a `title` of `'Main Window'`
on it.

You can add as many filters as you want, but generally you will only
need one.

### Pluralization

In cases where you want to find more than one type of object, you
simply need to pluralize the method name.

For example:

```ruby
window.buttons
```

is translated into something like this

![All The Buttons](images/all_the_buttons.jpg)

It is just that easy. The rules for pluralization are the same as
English since we are using the `ActiveSupport::Inflector` to do the
work of translating from pluralized form back to the singular
form. Even something like 'boxes' will get translated back to 'box'
and work as you expect.

Just as with a search that is not plural you can attach filters to
trim down the list of items that are returned and implicit searches
still must find something.

Pluralized searches is useful when you want to do some custom
refinement on a search, or if you need to make sure something is not
available. It can also be helpful when you want to explore the UI
element tree and find out what types of things are available.

### Kind Of

Remember earlier when I said the method name should be the class of
the element being searched for? Well, that was kind of a lie. Kind of,
get it? Have I killed the joke yet? No? Good.

The search class that you enter is actually matched using `#kind_of?`
instead of matching the classes exactly. And since class hierarchies
are properly setup, you can search for a base class and end up finding
subclasses.

For instance, not all buttons are of the class `AX::Button`, the
traffic light buttons are all different subclasses of `AX::Button`:
`AX::CloseButton`, `AX::MinimizeButton`, and `AX::ZoomButton`. There
are other several other subclasses of `AX::Button` as well. And
`AX::Button` itself is a subclass of `AX::Element`. Actually, all UI
elements are a subclass of `AX::Element`. What this means is that when
you have code like:

```ruby
app.close_button
```

you will only ever find something that is a `AX::CloseButton`, but
when you write something like:

```ruby
app.button
```

any button or subclass of button, including all the traffic light
buttons, can be found. I believe this makes search follow the
[DWIM](http://en.wikipedia.org/wiki/DWIM) principle, and allows you to
shorten the code you need to write in a number of cases. For example:

```ruby
app.window
```

can be substituted in place of

```ruby
app.standard_window
```

to find the first window. This makes sense if there is only one window
for the app, which is often the case. Similarly, if you are searching
from a container, such as an `AX::Group`, which only has a one button,
which happens to be a `AX::SortButton`, then you can say

```ruby
table.button
```

because it is not ambiguous and AXElements knows what you
mean. What if we take it a step further, what if made an even
broader search. Since _all_ UI elements are a subclass of
`AX::Element`, we could just write something like:

```ruby
app.element
```

and the first child would be returned. If we combined this with
pluralization, we could do something like

```ruby
app.elements
```

which will return an array with _all_ the children in it; so as always
you will need to be aware of the layout of the UI element tree when
you write a search. Otherwise you could end up finding something
completely different from what you wanted, such as searching for
`AX::Button` objects when However, this could just as easily bite you if you are being
general when there are many choices, such as with the traffic lights
example above.

In these cases you will want to be more specific about what you are
looking for, which can often allow you to skip the need for a search
filter. As an example, if you want to find the `AX::CloseButton`, then
you just need to write:

```ruby
window.close_button
```

since there will only ever be at most one `AX::CloseButton` for a
window.

Be specific when it sounds better and generalize more when you can, it
should make code read more naturally.

### Nested Searching

Sometimes you need to describe an element on the screen, and the only
reasonable way to do so is by describing some of the children of the
element that you are looking for.

For this requirement, nested searching exists, and very naturally
too. Pretend that you didn't already look at the next code snippet and
try to guess what a nested search looks like; you will probably be
correct. __Hint__: Searches can be nested arbitrarily deep and mixed
in with other filter parameters.

The answer, by example:

```ruby
window.outline.row(text_field: { value: 'Calendar' })
```

This would be asking for the outline row that has a text field with
the value of `'Calendar'`. The proper form for this would be:

```ruby
$ELEMENT.$KLASS($DESCANDANT: { $DESCENDANT_FILTER_ATTRIBUTE: $DESCENDANT_FILTER_VALUE1, ... }, ...)
```

Where `$DESCENDANT` plays the same role as `$KLASS`, but for a new
search that will be applied to candidates of `$KLASS` as a search result.

### Element Attribute Inference

The element attribute inference came about because a certain user who
did not understand the implementation details was trying to write some
code to search for element that matched to a title UI element. Before
going over the solution, we must first explain the problem.

If an element has a title UI element attribute, then the title UI
element will end up being another UI element. The problem with this is
that you then need to know about that element before you search and
the need to use the element as the filter value, for example:

```ruby
title_field = window.text_field(value: 'Name')
window.button(title_ui_element: title_field)
```

While that code is legitimate, it is not the most succinct way of
writing what was meant, and maybe not as clear as it could be. Perhaps
something more like:

```ruby
window.button(title_ui_element: 'Name')
```

Would also work without introducing inconsistencies in the language we
have created for searching. You are saying that button you are looking
for will be associated with a title UI element that says `'Name'`. You
can still match against the actual UI element if you want, but I think
this is much simpler.

This is not actually implemented internally to the searching
logic, it is implemented in each class that wants to
participate. Since search works by getting the value of the search
filter and checking if it is `#==` to the filter value, we just need
to implement `#==` on specific classes that we want to support custom
behaviour with. Examples of how this would work would be
{AX::TextField#==} and {AX::Button#==} and could be easily added to
other classes where it made sense. However, this type of idea can be
further expanded to cases that might not be so easily implemented and
is discussed in future prospects.

## Explicit Search

In the off chance that you need to make an explicit search, you can
trigger a search through {AX::Element#search}. In this case you give
the `$KLASS` as the first parameter of the method and the filters are
the remaining parameters.

## Caveats

The only caveat to note right now is that a UI element will always
return `false` when you ask if it can `#respond_to?` something that
would be an implicit search. This is because of the semantics of a
search do not make sense in the context of `#respond_to?`, it would
be as if {Accessibility::Search::Qualifier} had to be used. That is,
you would need to perform the search in order to know if the search
would succeed. This is both redundant and costly for the computer to
work through.

## The Future

Right now, the only case that is not handled is filtering by
parameterized attribute. The problem with this case is that I am not
sure where to stick the feature with regards to syntax.

Since you also need to encode the parameter with the attribute it is
difficult to express in terms of key-value pairs. Perhaps the key
could be an array so that the attribute can be included with the
key? That would be possible without too much work, but how would it
look. Does the syntax for search start to get too crazy at that point?
For instance, you cannot use the label syntax for hash keys with an
array (unfortunately), so code would look like:

```ruby
window.button([:string_for_range, CFRange.new(0,5)] => 'AXEle')
```

This topic is open to debate, but you should expect that I will play
the part of the devil's advocate.

### Ineference

There is also space for enhancement in the element attribute inference
feature(s). Wouldn't it be nice to be able to specify a filter value as a
range instead of a specific value? Probably not very often, but it is
something that could be done. Search filtering is not very flexible in
that regard right now, and maybe it never needs to be, but it is an
interesting change to think about.
