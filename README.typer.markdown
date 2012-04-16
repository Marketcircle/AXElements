# AXTyper

This gem is a component of
[AXElements](http://github.com/Marketcircle/AXElements). It provides
an interface for posting keyboard events to the system as well as a
mixin for parsing a string into a series of events.


## Quick Demo

The basics:

```ruby
    require 'accessibility/string'

    include Accessibility::String

    keyboard_events_for("Hey, there!").each do |event|
      KeyCoder.post_event event
    end
```

Something a bit more advanced:

```ruby
    require 'accessibility/string'

    include Accessibility::String

    keyboard_events_for("\\COMMAND+\t").each do |event|
      KeyCoder.post_event event
    end
```

A more detailed demonstration of what this library offers is offered in
[this blog post](http://ferrous26.com/blog/2012/04/03/axelements-part1/).


## Documentation

- [API documentation](http://rdoc.info/gems/AXTyper/frames)
- The AXElements [keyboarding tutorial](https://github.com/Marketcircle/AXElements/wiki/Keyboarding)


## Development

Development of this library happens as part of AXElements, but tests
and the API for this component should remain separate enough so that
it can be released as part of the AXTyper gem.

### Testing

Running tests for this subset of AXElements is best done by using the
`test:string` rake task, and also run `test:cruby` to make sure that
some MacRuby specific code didn't sneak into the keyboarding
component.

```shell
    rake test:string
    rake test:cruby
```

### TODO

The API for posting events is ad-hoc for the sake of demonstration;
AXElements exposes this functionality via `Kernel#type`. The standalone
API provided here could be improved.


## License

Copyright (c) 2012 Marketcircle Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of Marketcircle Inc. nor the names of its
  contributors may be used to endorse or promote products derived
  from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Marketcircle Inc. BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
