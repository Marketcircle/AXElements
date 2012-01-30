# Keyboard Events

Keyboard events are a system provided by Apple that allows you to
simulate keyboard input. The API for this in the `ApplicationServices`
framework, but there is an analogue in the `Acessibility` APIs which
has the additional option of directing the input to a specific application.

Using accessibility actions and setting attributes you can already
perform most of the interactions that would be possible with the
keyboard simulation. However, there are some things that you will need
to, or it will just make more sense to, simulate keyboard input. For
example, to make use of hot keys you would have to add extra actions
or attributes to a control in the application; that would be more
work, possibly prone to error, than simply simulating the hot key from
outside the application. In other situations you may specifically want
to test out keyboard navigation and so actions would not be a good
substitute. It may be that the APIs that AXElements provides for
typing just make more sense when writing tests or scripts.

## Typing with the DSL

The {Accessibility::DSL} mixin exposes keyboard events through the
`type` method. A simple example would look like this:

    type "Hello, #{ENV['USER']}! How are you today?\n"

And watch your computer come to life! The `type` command takes an
additional optional parameter that we'll get to later. The first
parameter is just a string that you want AXElements to type out. How
to format the string should be obvious for the most part, but some
things like the command key and arrows might not be so obvious.

## Formatting Strings

Letters and numbers should be written just as you would for any other
string. Any of the standard symbols can also be plainly added to a
string that you want to have typed. Here are some examples:

    type "UPPER CASE LETTERS"
    type "lower case letters"
    type "1337 message @/\/|) 57|_||=|="
    type "A proper sentence can be typed out (all at once)."

### Regular Escape Sequences

Things like newlines and tabs should be formatted just like they would
 in a regular string. That is, normal string escape sequences should
 "just work" with AXElements. Here are some more examples:

    type "Have a bad \b\b\b\b\b good day!"
    type "First line.\nSecond line."
    type "I \t like \t to \t use \t tabs \t a \t lot."
    type "Explicit\sSpaces."

### Custom Escape Sequences

Unfortunately, there is no built in escape sequence for deleting to
the right or pressing command keys like `F1`. AXElements defines some
extra escape sequences in order to easily represent the remaining
keys.

These custom escape sequences __shoud start with two `\` characters__,
as in this example:

    type "\\F1"

A custom escape sequence __should terminate with a space or the end of
the string__, as in this example:

    type "\\PAGEDOWN notice the space afterwards\\PAGEUP but not before"

The full list of supported custom escape sequences is listed in
{Accessibility::StringParser::ESCAPES}. Some escapes have an alias,
such as the right arrow key which can be escaped as `"\\RIGHT"` or as
`"\\->"`.

### Hot Keys

To support pressing multiple keys at the same time, also known as hot
keys, you must start with the custom escape sequence for the
combination and instead of ending with a space you should put a `+`
character to chain the next key. The entire sequence should be ended
with a space or nil. Some common examples are opening a file or
quitting an application:

    type "\\COMMAND+o"
    type "\\CONTROL+a Typing at the start of the line"
    type "\\COMMAND+\\SHIFT+s"

You might also note that `CMD+SHIFT+s` could also be:

    type "\\COMMAND+S"

Since a capital `S` will cause the shift key to be held down.

## Protips

In order make sure that certain sequences of characters are properly
escaped, it is recommended to simply always use double quoted
strings.

### Posting To A Specific Application

The second argument to the `type` command can be an {AX::Application}
object. If you do not include the argument, the events will be posted
to the system, which usually means the application that currently is
active. Note that you cannot be more specific than the application
that you want to send the events to, within the application, the
control that has keyboard focus will receive the events.

### Changing Typing Speed

You can set the typing speed at load time by setting the environment
variable `KEY_RATE`. See {Accessibility::Core::KEY\_RATE} for details on
possible values. An example of using it would be:

    KEY_RATE=SLOW irb -rubygems -rax_elements
    KEY_RATE=0.25 rspec gui_spec.rb

