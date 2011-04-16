# Searching

Searching the view hierarchy is the most powerful idea that this
toolkit provides by _significantly_ simplifying the process of
describing UI elements.

Search works by looking at the child elements of the current element,
and possibily at the children of the children elements, and so on and
so forth in a breadth first search through the UI hierarchy rooted at
the current node.

There are two features of the search that are important with regards
results of the search: pluralization and filtering.

Filtering is the important part of a search. The first argument of this
method, the element\_type, is the first, and only mandatory, filter;
the element_type filters on the class of an element.

Additional filters are specified as key/value pairs, where the key is a
method to call on a child element and the value must match or the child
does not match the search. You can attach as many filters as you want.

The other search feature is pluralization, which is when an 's' is
appended to the element_type that you are searching for; this causes
the search to assume that you wanted every element in the UI hierarchy
that meets the filtering criteria. It be used to make sure items are
no longer on screen.

If you do not pluralize, then the first element that meets all the
filtering criteria will be returned.
