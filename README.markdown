# AXElements

AXElements is a DSL abstraction built on top of the Mac OS X
Accessibility and CGEvent APIs that allows code to be written in a
very natural and declarative style that describes user interactions.

The framework is optimized for writing tests that require automatic
GUI manipulation, whether it be finding controls on the screen,
typing, clicking, or other ways in which a user can interact with the
computer.

## Getting Setup

You need to have the OS X developer tools installed in order to get
the full experience. Go ahead and install the tools now if you haven't
done that yet, I'll wait.

Once, you have the developer tools, you should install MacRuby, the
latest release should be sufficient, but nightly builds are usually
safe as well. If you are on Snow Leopard, you will also need to
install the
[Bridge Support Preview](http://www.macruby.org/blog/2010/10/08/bridgesupport-preview.html).

At this point you should install development dependencies. You can do
so with `bundler` if you have it, but it will be faster to use the
`setup_dev` task that has been provided. Simply type the following in
terminal:

    rake setup_dev

__NOTE__: if you are not using RVM, then you should use `macrake`
instead of `rake` for this command and anywhere else that you see
`rake` in the documentation. Also, remember that if you are not using
RVM with MacRuby but still have RVM installed then you will need to
disable RVM like so:

    rvm use system

Once you are setup, you can start looking through the tutorial
documentation to show you how to use AXElements. The first tutorial is
the {file:docs/Inspecting.markdown Inspecting tutorial}. The full list
of topics include:

* {file:docs/Inspecting.markdown Inspecting}
* {file:docs/Acting.markdown Acting}
* {file:docs/Searching.markdown Searching}
* {file:docs/Notifications.markdown Notifications}
* {file:docs/KeyboardEvents.markdown Keyboard}
* {file:docs/Debugging.markdown Debugging}
* {file:docs/NewBehaviour.markdown Adding Behaviour To AXElements}
* {file:docs/AccessibilityTips.markdown Making Your Apps More Accessibile}
* {file:docs/TestingExtensions.markdown Test Suite Extensions for RSpec, Minitest, etc.}

## Documentation

AXElements is documented using YARD, and includes a few tutorials in
the `docs/` directory. If you do not want to generate the
documentation yourself then you can go to
[rdoc.info](http://rdoc.info/gems/AXElements/frames).

Though it is not required, you may want to read Apple's
[Accessibility Overview](http://developer.apple.com/library/mac/#documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXModel/OSXAXmodel.html)
as a primer on some the technical underpinnings of AXElements.

## Test Suite

Before starting development on your machine, you should run the test
suite and make sure things are kosher. The nature of this library
requires that the tests take over your computer while they run. The
tests aren't programmed to do anything destructive, but if you
interfere with them then something could go wrong.

To run the tests you simply need to run the `test` task:

    rake test

__NOTE__: there may be some tests are dependent on Accessibility
features that are new in OS X Lion which will cause test failures on
OS X Snow Leopard. If you have any issues then you should look at the
output to find hints at what went wrong and/or log a bug. I will still
support Snow Leopard as long as MacRuby does, but I do not have easy
access to a Snow Leopard machine to verify that things still work.

### Benchmarks

Benchmarks are also included as part of the test suite, but they are
disabled by default. In order to enable them you need to set the
`BENCH` environment variable:

    BENCH=1 rake test

Benchmarks only exist for code that is known to be slow. I'm keeping
tabs on slow code so that I be confident about getting depressed when
it gets slower. Though, there is still room for improved performance
as well.

## Road Map

There are still a bunch of things that could be done to improve
AXElements. The README only contains an idealized outline of some of
the high-level items that should get done in the next couple of
releases. Smaller items are peppered through the code base and marked
with `@todo` tags.

### 0.7 (or maybe 1.0)

- Pre-loading AX hierarchy and attribute cache from
  `/System/Library/Accessibility/AccessibilityDefinitions.plist`
  + Not available on Snow Leopard, so it will have to wait anyways
  + Probably inccurs too much overhead at boot time right now
- Make a decision about NSArray#method_missing
- Merge notifications with actions as they are commonly combined
  + But how?
- Rewrite core module to handle errors more gracefully
- Mouse module cleanup and regression testing
- Test suite deduplication cleanup and better isolation
- Performance tweaks
- The OO abstraction leaks in a few places, code needs to be
  refactored without hurting performance too much
- Test framework helpers
  + Minitest
  + RSpec
- Thread Safety
  + Only if it becomes an issue, otherwise it might be better to
  forget thread safey to simplify and optimize existing code

### Future

- Screenshot taking and diff'ing abilities for those rare cases when
  you need it
- Address Book helpers, and other friends

## Contributing to AXElements

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2010-2011 Marketcircle Incorporated. All rights
reserved.

AXElements is available under the standard 3-clause BSD license. See
{file:LICENSE.txt LICENSE.txt} for further details.

