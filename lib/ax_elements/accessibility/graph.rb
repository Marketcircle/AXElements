##
# They see me graphing, they hating, patrolling they can't catch me
# graphing dirty.
class Accessibility::Graph

  ##
  # Exploit the ordering of a breadth-first enumeration to simplify the
  # creation of edges for the graph. This only works because the UI
  # hiearchy is a simple tree.
  #
  # @return [Array<Accessibility::Graph::Node>]
  attr_reader :edge_queue

  ##
  # List of nodes in the UI hierarchy.
  #
  # @return [Array<Accessibility::Graph::Node>]
  attr_reader :nodes

  ##
  # A node in the UI hierarchy. Used by {Accessibility::Graph} in order
  # to build Graphviz dot graphs.
  class Node

    # @return [AX::Element]
    attr_reader :ref

    ##
    # Unique identifier for the node.
    #
    # @return [String]
    attr_reader :id

    ##
    # Label to use for displaying the node.
    #
    # @return [String]
    attr_reader :label

    ##
    # Shape to draw the node as.
    #
    # @return [String]
    attr_reader :shape

    ##
    # Colour to fill the node with.
    #
    # @return [String]
    attr_reader :colour

    # @param [AX::Element]
    def initialize element
      @ref    = element
      @id     = "element_#{element.object_id}"
      @label  = element.class.to_s
      @shape  = nil # based on size? or based on type (literal, structural)?
      @colour = nil # rotate a la minitest?
    end
  end

  ##
  # List of edges in the graph.
  #
  # @return [Hash{Accessibility::Graph::Node=>Accessibility::Graph::Node}]
  attr_reader :edges

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
    Accessibility::BFEnumerator.new(nodes.first.ref).each do |element|
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
    graph << nodes_list
    graph << edges_list
    graph << "}\n"
  end

  ##
  # Generate the string for the list of nodes.
  #
  # @return [String]
  def nodes_list
    nodes.reduce('') do |string, node|
      string << "#{node.id} [label=\"#{node.label}\"]\n"
    end
  end

  ##
  # Generate the string for the list of edges.
  #
  # @return [String]
  def edges_list
    edges.delete_if { |_,v| v == :root } # remove hack
    edges.reduce('') do |string, pair|
      string << "#{pair.second.id} -> #{pair.first.id}\n"
    end
  end

end
