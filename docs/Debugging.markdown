# Debugging

This document includes instructions on using AXElements' built in
tools to help you debug issues with your scripts, or in cases where
you might find a bug in AXElements itself or MacRuby.

## Visibility

Sometimes an object that should be visible to accessibility does not
show up. Sometimes it will be invisible to the Accessibility Inspector
and sometimes it will be invisible to AXElements. This is because the
inspector uses hit testing to find objects and AXElements uses the
`children` and `parent` attributes (usually). Depending on which part
of the accessibility protocol is not being implemented correctly, one
or both tools might fail to work.

Fortunately, failures in the accessibility API are few and far
between. The one big,
[known issue](http://openradar.appspot.com/6832098) is with menu bar
items; you cannot work around this issue without hacking into private
Apple APIs. Specifically, you would need to override built in
accessibility methods in the class that implement the user interface
for NSStatusItem, which is a private class; or you could build your
status bar item as an NSMenuExtra, which is another private class. You
can find more tips on augmenting accessibility for apps in the
{file:docs/AccessibilityTips.markdown Accessibility Tips} document.

## Trees

Sometimes you need to see the big picture, the whole UI tree at
once or at least be able to see the root of the hierarchy from where
you are. For these troubling cases AXElements provides a few tools.

### Text Tree

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

For super fancy text trees, AXElements can generate dot graphs for
consumption by [Graphviz](http://www.graphviz.org/). In this case, you
want to call {Accessibility.graph} and pass the root of the tree you
want to have turned into a dot graph; you will get a string back that
you will then need to give to Graphviz in order to generate the visual
graph.

    File.open('graph.dot', 'w') do |file|
      app = Accessibility.application_with_name 'Terminal'
      file.write Accessibility.graph(app.window)
    end
    `dot graph.dot -Tpng > graph.png`
    `open graph.png`

### Text Tree Won't Print?

AXElements isn't perfect and it is possible that an edge case slipped
between the cracks. However, it's also possible that the problem is
actually how accessibility information is being vended out.

As an example, Radar #10040865 is a ticket that I filed with Apple
where they broke accessibility with search fields. The effect to
AXElements was that you could not search through the menu bar causing
a text dump to fail in a very difficult to trace manner.

In these cases you will need to use your deductive reasoning to figure
out where the problem is coming from. Fortunately, I have provided
some tools to help you along the way.

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

Custom exceptions have been created to help identify the point of
failure that would have caused a more cryptic exception to have been
raised instead. These custom exceptions also capture more metadata
about the problem that occurred which should give good hints as to what
went wrong.

### Search Failures

An {AX::Element::SearchFailure `SearchFailure`} will occur when you
perform an implicit search that fails to find anything.

In cases where implicit searches are chained, which happens frequently
with deep UI hierarchies, if one of the searches were to fail then you
would receive a `NoMethodError` about something having
failed. Sometimes the failure would happen because the search returned
`nil`, and of course `nil` would not respond to another search, though
this problem was easy to identify if you are familiar with the
AXElements source code; in other cases the failure would occur
somewhere in the search {Accessibility::Qualifier qualifier} or in the
{Accessibility::BFEnumerator enumerator}, and it was not always clear why.

The other feature of a search failure is that the exception message
will include an element back trace using {Accessibility.path}. This is
meant to give a hint about why the search failed.

### Attribute Not Writable

You will receive {AX::Element::ReadOnlyAttribute `ReadOnlyAttribute`}
exceptions only when you try to set an attribute that is not
writable. Again, this was originally designed to more easily identify the
point of failure when you try to write to an attribute that you should
not write to.

Specifically, `set_focus` is called by methods internally by
AXElements and at one time it was causing some problems when elements
were unexpectedly not allowing their `focused` attribute to be
written.

## Logging

The core level of AXElements has logging in every case that an error
code is returned. Though, it can show false positives because of
hiccups in the accessibility API or implementation that an app
provides; so it turned off by default. This feature is also going away
in favour of more intelligent error handling in the core wrapper.

When weird bugs are occuring, possibly even crashing MacRuby, you
should try turning on the logs and then trying the script again. You
might see some tell tale logs printed out right before the crash. You
can turn on logging right after you load AXElements, like so:

    require 'ax_elements'
    Accessibility.log.level = Logger::DEBUG

The standard log levels are available, the full set is available
[here](http://rdoc.info/stdlib/logger/1.9.2/Logger/Severity). `Logger::DEBUG`
will turn on all logs.
