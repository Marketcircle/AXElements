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

### Attribute Not Found

A very simple fail safe that AXElements uses is the
{AX::Element::LookupFailure `LookupFailure`} exception which will be
raised when you try to explicitly access an attribute which does not
exist, or at least does not exist for the particular element that you
are trying to access.

## Not So Custom Exceptions

Sometimes it is possible that the back trace for other exceptions can
get lost. This may be a result of
[MacRuby Ticket #1369](http://www.macruby.org/trac/ticket/1369), but
it might also be because of
[MacRuby Ticket #1320](http://www.macruby.org/trac/ticket/1320) or
some other freedom patch
that AXElements or ActiveSupport adds to the run time. I have not been
able to create a reduction of the problem yet.

The real problem is that loss of back trace happens for multiple
exception classes. The [work around](https://gist.github.com/1107314)
for this case is copied to `lib/ax_elements/macruby_extensions.rb`,
but has been commented out since it causes some regression tests to
fail. If you do not get a back trace with an error then you will need
to uncomment the freedom patches or copy them to your own script.

## Disabling Compiled Code

Back traces can be lost for reasons other than a bug. When using
compiled MacRuby code, you cannot get a Ruby level back trace in case
of an error. This feature is on the road map for MacRuby, but I am not
sure when it will be done.

In the mean time, if you suspect that the portion of a back trace that
would come from a compiled file is the problem, then you can disable
loading compiled files which will force MacRuby to load source ruby
files instead. You can disable loading compiled files by setting the
`VM_DISABLE_RBO` environment variable before running a script. You can
disable loading for a single session like so:

    VM_DISABLE_RBO=1 macruby my_script.rb

Other debugging options are also available from MacRuby itself. You
should check out [Hacking.rdoc](https://github.com/MacRuby/MacRuby/blob/master/HACKING.rdoc)
in the MacRuby source repository for more details.

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

## MacRuby Seems Slow

There are a few things that can cause MacRuby to be slow. At boot time
there are a number of factors, which I will cover, and at run time
there is really only one culprit.

### Long Load Times

When using certain gems, or when you have many gems installed, you
will notice that the load time for your scripts is very
long---possibly more than 10 seconds. There are many reasons why this
happens, some of which we can fix ourselves and some of which you will
have to wait for the MacRuby developers to fix.

#### Huge Literal Collections

Some gems contain source code with
[unbelievably large literal collections](https://github.com/sporkmonger/addressable/blob/master/lib/addressable/idna/pure.rb#L318),
such as the `addressable` gem. This is a problem for MacRuby for two
reasons.

First, it requires several thousand allocations at once. Most of
MacRuby's performance issues come from code that allocates too much,
and large collections can allocate several thousand objects all at
once.

The second problem is that MacRuby normally will try to JIT the code,
and the LLVM chokes on things this large. Some work has been done to
break the function up into smaller pieces (it used to take over 2
minutes to load the `addressable` gem), but it can still take a while
for MacRuby and the LLVM to work through the code

As it turns out, JIT isn't that great for short lived processes that
need to start up over and over again. In fact, JIT mode for MacRuby
was meant more for debugging.

The work around to this situation will have to come from upstream gem
developers and MacRuby itself. In the mean time, compiling these gems
will usually make them load _significantly_ faster. To compile gems,
you can install the
[`rubygems-compile`](https://github.com/ferrous26/rubygems-compile)
plug-in for rubygems. Follow the instructions from the plug-ins `README`
to learn how to use it and to know which version to install.

#### Complex Metaprogramming

Another problem that can cause long load times is complex
metaprogramming. Gems such as `rspec` do a lot of weird stuff at boot
that causes the MacRuby optimizer to do a lot of work. `rspec` alone
can add nearly 10 seconds to boot time. In this case you can tell the
optimizer to not try so hard; this will result in slower run time
performance, but it is likely worth the trade off in the case of
`rspec` (unless you compile).

You can set the optimization level for MacRuby just as you would
disable loading compiled code:

    # set the level to a number between 0 and 3, 3 is the highest
    VM_OPT_LEVEL=1 macruby my_script.rb

#### Large Code Bases

Large code bases taking a long time to load is not really an avoidable
situation---it happens with every project. Once again, JIT and
optimizer passes take up a lot of the load time.

In this case, it is best to compile your code (and test the compiled
version) in order to speed up boot time. You can combine compiled code
and still turn off optimization passes to get even better boot times,
but I am not sure it is worth the trade off at that point.

#### Rubygems

Rubygems suffers from a lot of technical debt. The process of
activating a gem incurs so many allocations that with as few as 25
installed gems can add an extra 2 seconds to your boot time. What is
worse, the performance degrades exponentially as you install more
gems.

The only fix for this is to cleanup and fix rubygems. Fortunately this
has been underway since the rubygems 1.4; the downside is that MacRuby
has customizations to rubygems that prevent users from upgrading
themselves. We need to wait for new MacRuby releases to bundle new
rubygems versions in order to fix this issue.

### Slow Runtime Performance

In my experience, slow runtime performance in MacRuby is almost always
the result of many allocations. If your code is runinng abnormally
slow then it is likely that you are allocating a lot of memory without
realizing it, and you should compare performance to CRuby if it is
important (and if it is possible to run the code on CRuby).

Remember that things like literal strings have to be copied every time
the line of code they are on is run, whereas immutable things like
symbols do not have to be copied. At the same time, if you pass a
symbol to a method that will coerce the symbol to a string then you
haven't saved an allocation.

Try to use in-place mutations when it is safe. An example would be
when you have to perform multiple changes to an object in a single
method, you only have to create a new copy the first time and then use
the same copy for all the other changes. Example code would look like this:

    def transform string
      new_string = string.gsub /pie/, 'cake'
      new_string.gsub! /hate/, 'love'
      new_string.upcase!
      new_string
    end

Remember that built-in in-place methods tend to return `nil` if they
don't make any changes, which means you need to explicitly return the
new object at the end of the method. There are still many other easily
avoidable cases where you could end up allocating a lot of memory
which are not covered. If it is important you willl just have to
analyze your code.

Sometimes allocating a lot of memory is not avoidable; running RSpec
would be an example of this. In these cases you just have to bite the
bullet.

## Don't Be Afraid To Log Bugs

Or look at the AXElements source code for that matter. The source is
well documented and hopefully not too clever, so it shouldn't be too
hard to figure things out. You can log AXElements bugs on Github where
the source is being hosted.

Though, sometimes the problem will be a MacRuby problem and the best
way to get it fixed is to
[log a bug](http://www.macruby.org/trac/). You will need to create an
account with them to log bugs.

I also recommend that you subscribe to the
[MacRuby mailing list](http://lists.macosforge.org/mailman/listinfo.cgi/macruby-devel)
to keep up to date on MacRuby developments. You can send in questions
if you are unsure about a certain behaviour, even potential bugs. It
is not a high traffic mailing list so it won't blow up your mailbox
when you subscribe.
