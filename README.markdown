# AXElements

AXElements is a DSL abstraction built on top of the Mac OS X
Accessibility and CGEvent APIs that allows code to be written in a
very natural and declarative style that describes user interactions.

The framework is optimized for writing tests that require automatic
GUI manipulation, whether it be finding controls on the screen,
typing, clicking, or other ways in which a user can interact with the
computer.

## Examples

Perhaps you want to do something with the finder. This example opens a
new Finder window, goes to the Applications directory, quick looks the
first app and then opens the application:

```ruby
    require 'rubygems'
    require 'ax_elements'

    finder = Accessibility.application_with_bundle_identifier 'com.apple.finder'
    set_focus finder

    menu = finder.menu_bar_item(title: 'File')
    press menu
    press menu.menu_item(title: 'New Finder Window')
    sleep 1 # otherwise everything happens as fast as possible

    window = finder.main_window
    click window.outline.row(static_text: { value: 'Applications' })
    press window.toolbar.button(description: 'Quick Look')
    sleep 1

    press finder.quick_look.button(identifier: 'QLControlOpen')
```

A simpler example would be changing the system volume by moving the
slider in the menu bar:

```ruby
    require 'rubygems'
    require 'AXElements'

    ui = Accessibility.application_with_bundle_identifier 'com.apple.systemuiserver'
    volume = ui.menu_extra(description: 'system sound volume')

    click volume
    15.times { decrement volume.slider }
    15.times { increment  volume.slider }
```

## Getting Started

The
[documentation](http://rdoc.info/github/Marketcircle/AXElements/master/frames)
is the best place to get started, it will help you
get setup and includes a few tutorials with examples. Documentation is
hosted by rdoc.info, but you can also generate it yourself using YARD.

Documentation is stored in the `docs/` directory, but the
documentation includes a number of cross references and even some
pictures so you will lose a lot of the quality if you view them as
plain text. You can view the generated documentation at
[rdoc.info](http://rdoc.info/github/Marketcircle/AXElements/master/frames).

At the moment, it is best to install AXElements from source:

```bash
    git clone https://github.com/Marketcircle/AXElements.git
    cd AXElements

    # if you use MacRuby with RVM
    rake setup_dev
    rake install

    # if you don't use MacRuby with RVM
    sudo rake setup_dev
    sudo rake install
```

## Development

A stable release of AXElements is under way! The main focus is an
overall refactoring to create a more robust core, end user features
will become more consistent, and performance will
increase. Documentation will be overhauled and more examples will be
added. It will be magical, so we're code naming the next version
"Clefairy".

![The Moon](https://github.com/Marketcircle/AXElements/raw/master/docs/images/next_version.png)

Proper releases to rubygems will be made as milestones are reached.

```bash
    # If you use MacRuby with RVM
    gem install AXElements --pre

    # If you don't use MacRuby with RVM
    sudo macgem install AXElements --pre
```

## Contributing to AXElements

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2010-2012 Marketcircle Incorporated. All rights
reserved.

AXElements is available under the standard 3-clause BSD license. See
LICENSE.txt for further details.
