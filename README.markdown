# AXElements

AXElements is a DSL abstraction on top of the Mac OS X Accessibility Framework
that allows code to be written in a very natural and declarative style that
describes user interactions.

## General TODO

- better super class choosing when creating classes at run time
  + a close button should be the subclass of a button, but you may
  need to also create the button class, but in this case superclass
  should be the general role of the element
- tests should never need to call private methods or inspect state
  that is not normally exposed
  + this can be done by tiering the test suite and relying on API from
  the lower tier (higher tier tests will not run until after the lower
  tier finishes and passes)
- change AX.perform\_action\_of\_element to AX.action\_of\_element
  + various other API name changes to make AX have a consistent naming
  scheme
- add direct accessors to AX::Element (when the exact constant name is known)

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

