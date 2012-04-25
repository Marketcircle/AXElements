##
# DOT graph generator for AXElements. It can generate the digraph code
# for a UI subtree. That code can then be given to GraphViz to generate
# an image for the graph.
#
# You can learn more about generating graphs in the
# [Debugging tutorial](http://github.com/Marketcircle/AXElements/wiki/Debugging).
#
# [Learn more about GraphViz](http://www.graphviz.org/).
class Accessibility::Graph

  ##
  # @todo Graphs could be nicer looking. That is, nodes could be much
  #       more easily identifiable, by allowing different classes to tell
  #       the node more about itself. A mixin module/protocol should
  #       probably be created, just as with the inspector mixin, and added
  #       to abstract base and overridden as needed in subclasses. In this
  #       way, an object can be more specific about what shape it is, how
  #       it is coloured, etc.
  #       Reference: http://www.graphviz.org/doc/info/attrs.html
  #
  # A node in the UI hierarchy. Used by {Accessibility::Graph} in order
  # to build Graphviz DOT graphs.
  class Node

    # @return [String]
    attr_reader :id

    # @return [AX::Element]
    attr_reader :element

    # @param [AX::Element]
    def initialize element
      @element = element
      @id      = "element_#{element.object_id}"
    end

    # @return [String]
    def to_dot
      "#{@id} #{identifier} [shape=#{shape}] [style=#{style}] [color=#{colour}]"
    end


    private

    def identifier
      klass = @element.class.to_s.split(NAMESPACE).last
      ident = @element.pp_identifier.dup
      if ident.length > 12
        ident = "#{ident[0...12]}..."
      end
      ident << '"' if ident[1] == QUOTE && ident[-1] != QUOTE
      ident.gsub! /"/, '\"'
      ident.gsub! /\\/, '\\'
      "[label = \"#{klass}#{ident}\"]"
    end

    def shape
      (@element.attribute(:focused) && OCTAGON) ||
      (@element.actions.empty? && OVAL)         ||
      BOX
    end

    def style
      # fill in the node if it is disabled (greyed out effect)
      if @element.attributes.include?(:enabled)
        return FILLED unless @element.attribute(:enabled)
      end
      # bold if focused and no children
      if @element.attribute(:focused)
        return BOLD if @element.size_of(:children).zero?
      end
      SOLID
    end

    def colour
      if @element.attributes.include?(:enabled)
        return GREY unless @element.attribute(:enabled)
      end
      BLACK
    end

    # @private
    # @return [String]
    EMPTY_STRING = ''
    # @private
    # @return [String]
    NAMESPACE    = '::'
    # @private
    # @return [String]
    QUOTE        = '"'
    # @private
    # @return [String]
    OVAL         = 'oval'
    # @private
    # @return [String]
    BOX          = 'box'
    # @private
    # @return [String]
    OCTAGON      = 'doubleoctagon'
    # @private
    # @return [String]
    BOLD         = 'bold'
    # @private
    # @return [String]
    FILLED       = 'filled'
    # @private
    # @return [String]
    SOLID        = 'solid'
    # @private
    # @return [String]
    GREY         = 'grey'
    # @private
    # @return [String]
    BLACK        = 'black'
  end

  ##
  # An edge in the UI hierarchy. Used by {Accessibility::Graph} in order
  # to build Graphviz DOT graphs.
  class Edge

    ##
    # The style of arrowhead to use
    #
    # @return [String]
    attr_accessor :style

    # @param [Accessibility::Graph::Node]
    # @param [Accessibility::Graph::Node]
    def initialize head, tail
      @head, @tail = head, tail
    end

    # @return [String]
    def to_dot
      arrow = style ? style : 'normal'
      "#{@head.id} -> #{@tail.id} [arrowhead = #{arrow}]"
    end

  end


  ##
  # List of nodes in the UI hierarchy.
  #
  # @return [Array<Accessibility::Graph::Node>]
  attr_reader :nodes

  ##
  # List of edges in the graph.
  #
  # @return [Array<Accessibility::Graph::Edge>]
  attr_reader :edges

  # @param [AX::Element]
  def initialize root
    root_node   = Node.new(root)
    @nodes      = [root_node]
    @edges      = []

    # exploit the ordering of a breadth-first enumeration to simplify
    # the creation of edges for the graph. This only works because
    # the UI hiearchy is a simple tree.
    @edge_queue = Array.new(root.children.size, root_node)
  end

  ##
  # Construct the list of nodes and edges for the graph.
  #
  # The secret sauce is that we create an edge queue to exploit the
  # breadth first ordering of the enumerator, which makes building the
  # edges very easy.
  def build!
    Accessibility::Enumerators::BreadthFirst.new(nodes.last.element).each do |element|
      nodes << node = Node.new(element)
      edges << Edge.new(node, @edge_queue.shift)
      # should use #size_of(:children), but that doesn't in all cases
      @edge_queue.concat Array.new(element.children.size, node)
    end
    @built = true
  end

  ##
  # Generate the `dot` graph code. You should take this string and
  # feed it to the `dot` program to have it generate the graph.
  #
  # @return [String]
  def to_dot
    graph  = "digraph {\n"
    graph << nodes.map(&:to_dot).join(";\n")
    graph << "\n\n"
    graph << edges.map(&:to_dot).join(";\n")
    graph << "\n}\n"
  end

end
