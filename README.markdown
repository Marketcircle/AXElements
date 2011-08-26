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

At this point you should be able to run `macrake`. Which by default
will likely complain about things missing. You can easily install all
development dependencies by running the `setup_dev` task like so:

    macrake setup_dev

If you get an error about not having permissions then you will need to
add `sudo` to the beginning of the command.

Once you are setup, you can start looking through the tutorial
documentation, probably starting with the
{file:docs/Inspecting.markdown Inspecting tutorial}:

* {file:docs/Inspecting.markdown Inspecting}
* {file:docs/Acting.markdown Acting}
* {file:docs/Searching.markdown Searching}
* {file:docs/Notifications.markdown Notifications}
* {file:docs/KeyboardEvents.markdown Keyboard manipulation}
* {file:docs/Debugging.markdown Debugging Problems}
* {file:docs/NewBehaviour.markdown Adding Behaviour}
* {file:docs/RSpecMinitest.markdown RSpec and Minitest extensions}

## Documentation

AXElements is documented using YARD, and includes a few small
tutorials in the `docs` directory. If you do not want to generate the
documentation yourself, we are hosting the documentation on our
internal network on [quartz](http://docs.marketcircle.com:8808/).

Though it is not required, you should read Apple's
[Accessibility Overview](http://developer.apple.com/library/mac/#documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXModel/OSXAXmodel.html)
as a primer on some the technical underpinnings of AXElements.

## Test Suite

Before starting development on your machine, you should run the test
suite and make sure things are kosher. The nature of this library
requires that the tests take over your computer while they run. The
tests aren't programmed to do anything destructive, but if you
interfere with them then something could go wrong.

To run the tests you simply need to run the `test` task:

    macrake test

__NOTE__: some tests are dependent on Accessibility features that are
new in OS X Lion and those tests will fail on OS X Snow Leopard.

Benchmarks are also included as part of the test suite, but they are
disabled by default. In order to enable them you need to set the
`BENCH` environment variable:

    BENCH=1 macrake test

Benchmarks only exist for code that is known to be slow. I'm keeping
tabs on slow code so that I be confident about getting depressed when
it gets slower.

## Road Map

There are still a bunch of things that could be done to improve
AXElements. The README only contains an idealized outline of some of
the high-level items that should get done in the next couple of releases.

### 0.7 (or maybe 1.0)

- Pre-loading AX hierarchy and attribute cache from
  `/System/Library/Accessibility/AccessibilityDefinitions.plist`
  + DO NOT load_plist and then parse, use NSXMLParser to have less
  overhead, but it still might allocate too much to be done at boot
  time
- Make a decision about NSArray#method_missing
- Merge notifications with actions as they are commonly combined
- Rewrite core module to handle errors more gracefully
- Cleanup properly in failure cases for notifications
- Mouse module cleanup and regression testing
- Test suite duplication cleanup and better isolation
- Performance tweaks

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

Copyright (c) 2010-2011 Marketcircle Incorporated. See {file:LICENSE.txt LICENSE.txt} for further details.

