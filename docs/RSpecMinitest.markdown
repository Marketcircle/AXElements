# Test Helpers

There are some types of assertions that you would like to make during
testing that simply does not make sense using the build in
assertions. These can include things like existence checks which you
would have to implement by searching, or ... that is really the only
one I have so far :)

## RSpec

RSpec 2 is the Marketcircle choice for implementing functional and
behavioural tests for apps using AXElements. It is great and offers
the flexibility and features that make using it very good for large
test suites.

You can load the RSpec matchers that AXElements adds by requiring

    require 'rspec/ax_elements'

### Existence

Checking for the existence of an object in RSpec with AXElements looks
a bit awkward:

    window.search(:button).should be_empty
    # or
    window.search(:button).should_not be_empty

That does not communicate intent as clearly as it could. What if you
could say something like:

    window.should have_a :button
    # or
    window.should_not have_a :button

What if you have filters? Well, that is handled as well, though maybe
not as nicely:

    window.should have_a(:button).with(title: 'Hello')

## Minitest

AXElements uses minitest for its own regression test suite. Minitest
is pretty cool, and there is good cause to support it as well. To that
end, we have provided the equivalent assertions.

You can load it like so:

    require 'minitest/ax_elements'

