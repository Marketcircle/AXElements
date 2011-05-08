# AXElements

AXElements is a DSL abstraction on top of the Mac OS X Accessibility Framework
that allows code to be written in a very natural and declarative style that
describes user interactions.

## Documentation

AXElements is documented using YARD, and includes a few small
tutorials in the `docs` directory. The starting point is [here](docs/AXElements.markdown).

## Test Suite

The nature of this library requires that the tests take over your
computer while they run.

The tests aren't programmed to do anything destructive, but if you
interfere with them something could go wrong.

## Road Map

An idealized outline of how things will progress in the next couple of releases

### 0.5

- better super class choosing when creating classes at run time
  + a close button should be the subclass of a button, but you may
  need to also create the button class, but in this case superclass
  should be the general role of the element
    * then we can search using #kind_of instead of #is_a, though I am
    not convinced that this change would be beneficial
- notifications system needs to be cleaned up
  + notification name resolution does not need to happen in the
  Element class, or does it?
  + needs to cleanup properly in failure cases
- Search needs to be expanded
  + First it needs to be cleaned up
  + It needs to handle exceptions better
  + Needs to support more complex filtering criteria
- Update rubygems in MacRuby or import the specific parts of Active
  Support that AXElements depends on
- Tests should rely on a special app that is bundled just for tests
  instead of trying to interact with different assumed parts of the
  environment
  + this should help with all the skipped tests and also the
  benchmarks that should be implemented

### 0.6 (or maybe 1.0)

- Keyboard module
  + support a much larger set of keys and key combinations that can be
  pressed
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

