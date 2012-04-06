##
# DOT graph generator for AXElements. It can generate the digraph code
# for a UI subtree. That code can then be given to GraphViz to generate
# an image for the graph.
#
# You can learn more about generating graphs in the
# {file:docs/Debugging.markdown Debugging} tutorial.
class Accessibility::Graph

  ##
  # @todo Graphs could be a lot nicer looking. That is, nodes could be much
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
      "#{@id} #{identifier} #{shape}"
    end


    private

    EMPTY_STRING = ''
    NAMESPACE = '::'

    def identifier
      klass = @element.class.to_s.split(NAMESPACE).last
      ident = @element.pp_identifier
      ident.gsub! /"/, '\"'
      "[label = \"#{klass}#{ident}\"]"
    end

    def shape
      @element.actions.empty? ? OVAL : BOX
    end

    def enabled
      FILL if @element.enabled?
    end

    def focus
      BOLD if @element.focused?
    end

    OVAL = '[shape = oval]'
    BOX  = '[shape = box]'
    BOLD = '[style = bold]'
    FILL = '[style = filled] [color = "grey"]'
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
      @head = head
      @tail = tail
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
    @edge_queue = Array.new(root.size_of(:children), root_node)
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
      @edge_queue.concat Array.new(element.size_of(:children), node)
    end
  end

  ##
  # Generate the `dot` graph code. You should take this string and
  # feed it to the `dot` program to have it generate the graph.
  #
  # @return [String]
  def to_dot
    graph  = "digraph {\n"
    graph << nodes.map(&:to_dot).join("\n")
    graph << "\n\n"
    graph << edges.map(&:to_dot).join("\n")
    graph << "\n}\n"
  end

end
