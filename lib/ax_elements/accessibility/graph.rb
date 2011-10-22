##
# They see me graphing, they hating, patrolling they can't catch me
# graphing dirty.
class Accessibility::Graph

  ##
  # A node in the UI hierarchy. Used by {Accessibility::Graph} in order
  # to build Graphviz dot graphs.
  class Node

    ##
    # Unique identifier for the node.
    #
    # @return [String]
    attr_reader :id

    # @return [AX::Element]
    attr_reader :ref

    # @param [AX::Element]
    def initialize element
      @ref = element
      @id  = "element_#{element.object_id}"
    end

    # @return [String]
    def to_s
      label   = "[label=\"#{ref.class}\"]"

      enabled = if ref.respond_to?(:enabled) && !ref.enabled?
                  '[style = filled] [color = "grey"]'
                else
                  ::EMPTY_STRING
                end

      focus   = if ref.respond_to?(:focused)
                  if ref.focused?
                    '[style = bold]'
                  end
                else
                  ::EMPTY_STRING
                end

      "#{id} #{label} #{enabled} #{focus}"
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
  # @return [Hash{Accessibility::Graph::Node=>Accessibility::Graph::Node}]
  attr_reader :edges

  ##
  # Exploit the ordering of a breadth-first enumeration to simplify the
  # creation of edges for the graph. This only works because the UI
  # hiearchy is a simple tree.
  #
  # @return [Array<Accessibility::Graph::Node>]
  attr_reader :edge_queue

  # @param [AX::Element]
  def initialize root
    @nodes      = []
    @edges      = {}
    @edge_queue = [:root] # hack
    add_node      root
  end

  ##
  # Construct the list of nodes and edges for the graph...
  def build!
    Accessibility::BFEnumerator.new(nodes.last.ref).each do |element|
      add_node element
    end
  end

  ##
  # Add a node to the graph, links edges for which it is a tail, and
  # and prepare edges where the node will be the head.
  #
  # @param [AX::Element]
  def add_node element
    node   = Node.new(element)
    nodes << node
    edges[node] = edge_queue.shift
    if element.respond_to? :children
      element.size_of(:children).times do
        edge_queue << node
      end
    end
  end

  ##
  # Generate the `dot` graph code. You should take this string and
  # feet it to the `dot` program to have it generate the graph.
  #
  # @return [String]
  def to_s
    graph  = "digraph {\n"
    graph << nodes.map { |node| "#{node.to_s}\n" }.join
    edges.delete_if { |_,v| v == :root } # remove hack
    graph << edges.map { |edge| "#{edge.second.id} -> #{edge.first.id}\n" }.join
    graph << "}\n"
  end

end
