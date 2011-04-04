Keyboard Events
===============

In some cases you cannot, or do not want to,  set the value of a field
directly by assigning to the accessibility object's value
attribute. In these cases you can post keyboard events to an
application object.

Keyboard events must be posted to an application object.

Key codes are independant of the layout in the sense that they are
absolute key positions on the keyboard and that different layouts will
fuck things up differently.

Escape Sequences
----------------

A number of custom escape sequences have been added in order to allow easy
encoding of all key sequences/combinations.

<table style="1px solid black">
<tr><td>Key</td><td>Escape Sequence</td></tr>
<tr><td>Control</td><td>`\^`</td></tr>
<tr><td>Command</td><td>`\C`</td></tr>
<tr><td>Option/Alt</td><td>`\O`</td></tr>
<tr><td>Tab</td><td>`\t`</td></tr>
<tr><td>Escape</td><td>`\e`</td></tr>
<tr><td>Space</td><td>` `</td></tr>
</table>

<a href="images/imtx-virtual-keycodes.png">
<img style="heigh: 500px; width: 950px" src="/docs/file/docs/images/imtx-virtual-keycodes.png" />
</a>

