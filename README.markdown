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
install the Bridge Support Preview.

At this point you should be able to run `macrake`. Which by default
will probably complain about things missing. Now you should install
the dependency gems by running `macrake install_deps`; if you get an
error about not have permission you will need to add `sudo` to the
command.

## Documentation

AXElements is documented using YARD, and includes a few small
tutorials in the `docs` directory. The starting point is
{file:docs/AXElements.markdown}.

## Test Suite

The nature of this library requires that the tests take over your
computer while they run. The tests aren't programmed to do anything
destructive, but if you interfere with them something could go wrong.

First you need to build the test fixture, which you can do by running
`macrake fixture`. Then you can run the tests by running
`macrake test`.

## Road Map

An idealized outline of how things will progress in the next couple of releases

### 0.5 (Luxray Tamer)

- notifications system needs to be cleaned up
  + notification name resolution does not need to happen in the
  Element class, or does it?
  + needs to cleanup properly in failure cases
- Tests should rely on a special app that is bundled just for tests
  instead of trying to interact with different assumed parts of the
  environment
  + this should help with all the skipped tests and also the
  benchmarks that should be implemented
- Keyboard module
  + support a much larger set of keys and key combinations that can be
  pressed

### 0.6 (or maybe 1.0)

- Mouse module cleanup
- Performance tweaks

### Future

- Screenshot taking and diff'ing abilities for those rare cases when
  you need it

## Contributing to AXElements

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2010-2011 Marketcircle Incorporated. See LICENSE.txt for further details.

