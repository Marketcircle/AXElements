# AXElements

AXElements is a DSL andabstraction and an OO interface on top of the
Mac OS X Accessibility Framework that allows code to be written in a
very natural and declarative style that describes user interactions.

## Getting Setup

You need to have the OS X developer tools installed in order to get
the full experience. Go ahead and install the tools now if you haven't
done that yet, I'll wait.

Once, you have the developer tools, you should install MacRuby, the
latest release should be sufficient, but nightly buids are usually
safe as well. If you are on Snow Leopard, you will also need to
install the
[Bridge Support Preview](http://www.macruby.org/blog/2010/10/08/bridgesupport-preview.html).

At this point you should be able to run `macrake`. Which by default
will likely complain about things missing. You can easily install all
development dependencies by running the `setup_dev` task like so:

    macrake setup_dev

If you get an error about not having permissions then you will need to
add `sudo` to the beginning of the command.

## Documentation

AXElements is documented using YARD, and includes a few small
tutorials in the `docs` directory. The starting point is
{file:docs/AXElements.markdown}. When you are on the Marketcircle
internal network you should be able to access the [documentation
website](http://docs.marketcircle.com:8808/) to save you the time of
running the server yourself.

## Test Suite

The nature of this library requires that the tests take over your
computer while they run. The tests aren't programmed to do anything
destructive, but if you interfere with them something could go wrong.

First you need to build the test fixture, which you can do by running
`macrake fixture`. Then you can run the tests by running
`macrake test`. NOTE: some tests are dependent on Accessibility
features that are new in OS X Lion and those tests will fail on OS X
Snow Leopard.

## Road Map

There are still a bunch of things that could be done to improve
AXElements. The README only contains an idealized outline of some of
the high-level items that should get done in the next couple of releases.

### 0.7 (or maybe 1.0)

- Pre-loading AX hierarchy and attribute cache from
  /System/Library/Accessibility/AccessibilityDefinitions.plist
  + DO NOT load_plist and then parse, use NSXMLParser
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

