# Debugging

Some times you need to see the big picture, the whole UI tree at
once or at least be able to see the root of the hierarchy from where
you are. For these troubling cases, AXElements provides a few tools.

## Text Tree

Printing a text tree is similar to how a UI dump works with iOS. It
will print the entire tree out on the command line using indentation
to indicate how far down the tree each element is and also to signify
which element is the parent.

    Accessibility.tree(app).dump

## Dot Graph

Dot graphs are a little bit tricky, they require you to install
[Graphviz](http://www.graphviz.org/) and then you will need to ask
AXElements to send some tree data over to Graphviz.

## Custom Exceptions

AXElements provides some customized exceptions in the OO layer that
should help give you much better hints at what went wrong when you
have a problem.

### Search Failures

### Attribute Not Writable

### Attribute Not Found
