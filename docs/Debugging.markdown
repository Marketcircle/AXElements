# Debugging

Some times you need to see the big picture, the whole UI tree at
once or at least be able to see the root of the hierarchy from where
you are. For these troubling cases AXElements provides a few tools.

## Text Tree

Printing a text tree is similar to how a UI dump works with
accessibility on iOS. AXElements does improve a bit on its iOS
equivalent. Simply using the Accessibility Inspector does not give you
a good picture of the whole tree and with complicated structures it is
easy to make mistakes navigating the UI tree.

The text tree comes formatted for you, and you can simply print it out
to the console. The output uses indentation to indicate how far down
the tree each element is, and the first element up the tree with one
indentation level less will always be the parent for an element.

Printing out a text tree in the console is very easy. First you generate
the text dump and then you print it out:

    puts Accessibility.dump(app)

This method is useful when you are having difficulties with
search. Sometimes when searching you will end up finding the wrong
element because your search query was ambiguous and you didn't
know at the time. Printing out a dump can often be all the help you
need in order to identify your problem.

However, if the standard `#inspect` isn't doing it for you, you can
perform your own inspection every element in a tree yourself using the
built in enumerators. Searches use the {Accessibility::BFEnumerator},
but the text tree dump method uses {Accessibility::DFEnumerator}.

### Dot Graph

__NOTE__: This feature isn't actually done yet.

For super fancy text trees, AXElements can generate dot graphs for
consumption by [Graphviz](http://www.graphviz.org/). In this case, you
want to call {Accessibility.graph} and pass the root of the tree you
want to have turned into a dot graph; you will get a string back that
you will then need to give to Graphviz in order to generate the visual
graph.

## All The Way Up

Sometimes you don't need a whole tree to be printed out. Sometimes
just seeing the path from an element to the top level element is
enough. {Accessibility.path} is your friend in this case, it will
provide you with an array of UI element objects, each successive
element will be the parent of the previous element. This is almost
like the view that the Accessibility Inspector provides.

## Custom Exceptions

AXElements provides some customized exceptions in the OO layer that
should help give you much better hints at what went wrong when you
have a problem.

### Search Failures

An {AX::Element::SearchFailure SearchFailure} will occur when you
perform an implicit search that fails to find anything.

In cases where implicit searches are chained, when one of the searches
fails you will get a `NoMethodError` about something having
failed. Earlier on in AXElements development it was difficult to
figure out where the point of failure was and this helped out quite a
bit.

The other feature of a search failure is that the exception message
will include an element back trace using {Accessibility.path}. This is
meant to give a hint about why the search failed.

### Attribute Not Writable

You can receive {AX::Element::ReadOnlyAttribute ReadOnlyAttribute}
exceptions only when you try to set an attribute that is not
writable. Again, this was originally designed to more easily identify the
point of failure when you try to write to an attribute that you should
not write to.

Specifically, `#set_focus` is called by methods under the hood and it
was causing some problems when elements were unexpectedly not allowing
their `focused` attribute to be written.

### Attribute Not Found

A very simple fail safe that AXElements uses is the
{AX::Element::LookupFailure LookupFailure} exception which will be
raised when you try to explicitly access an attribute which does not
exist, or at least does not exist for the particular element that you
are trying to access.
