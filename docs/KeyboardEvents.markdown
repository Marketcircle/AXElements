# Keyboard Events

@todo Still a little bit to do in this doc

In some cases you cannot, or do not want to,  set the value of a field
directly by assigning to the accessibility object's value
attribute. In these cases you can post keyboard events to an
application object.

Other cases for using keyboard input simulation might include keyboard
navigation or hotkey activation.

The DSL exposes Keyboard events through the `type` keyword. An example
would look like this:

```ruby
type "hello, world!", app
```

In order make sure that certain sequences of characters are properly
transcribed to the screen you should be consistent about using double
quotes, `"`,  for literal strings. An escape sequence should begin
`\\`.

First the keyword `type`, and then the string you want to type
out. Finally, there is a second argument, which is optional, that
should be the application that you wish to send the keyboard input
to; if you do not include the argument, then the input will go to the
currently activate application.

## Behaviour

The method is asynchronous. It appears to type information in at the
keyboard repeat rate, but I have yet to check that out.

## Escape Sequences

A number of custom escape sequences have been added in order to allow easy
encoding of all key sequences/combinations.

<table style="1px solid black">
<tr><td>Key</td><td>Escape Sequence</td></tr>
<tr><td>Delete Backwards (Backspace)</td><td>`\b`</td></tr>
<tr><td>Enter</td><td>`\n` or `\r`</td></tr>
<tr><td>Control</td><td>`\^`</td></tr>
<tr><td>Command</td><td>`\C`</td></tr>
<tr><td>Option/Alt</td><td>`\O`</td></tr>
<tr><td>Tab</td><td>`\t`</td></tr>
<tr><td>Escape</td><td>`\e`</td></tr>
<tr><td>Space</td><td>` `</td></tr>
<tr><td>Scroll To Top</td><td>`\x01`</td></tr>
<tr><td>Scroll To Bottom</td><td>`\x04`</td></tr>
<tr><td>Page Down</td><td>`\f`</td></tr>
<tr><td>Left Arrow</td><td>`\\<->`</td></tr>
<tr><td>Right Arrow</td><td>`\\->`</td></tr>
<tr><td>Down Arrow</td><td>`\DOWN`</td></tr>
</table>
