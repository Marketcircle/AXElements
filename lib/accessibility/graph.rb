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
      enabled = if ref.respond_to?(:enabled) && !ref.enabled?
                  '[style = filled] [color = "grey"]'
                else
                  EMPTY_STRING
                end

      focus   = if ref.respond_to? :focused
                  ref.focused? ? '[style = bold]' : EMPTY_STRING
                else
                  EMPTY_STRING
                end

      shape   = ref.actions.empty? ? '[shape = oval]' : '[shape = box]'

      "#{id} #{identifier} #{enabled} #{focus} #{shape}"
    end


    private

    EMPTY_STRING = ''

    def identifier
      klass = ref.class.to_s.split('::').last

      if ref.respond_to? :value
        val = ref.attribute :value
        if val.kind_of? NSString
          return "[label = \"#{klass} #{val}\"]" unless val.empty?
        else
          # we assume that nil is not a legitimate value
          unless val.nil?
            return "[label = \"#{klass} value=#{val.inspect}\"]"
          end
        end
      end

      if ref.respond_to? :title
        val = ref.attribute(:title)
        if val && !val.empty?
          return "[label = \"#{klass} #{val.inspect}\""
        end
      end

      # @todo Should create a special edge to the title ui element
      if ref.respond_to? :title_ui_element
        #val = attribute :title_ui_element
        return "[label = \"#{klass}\"]" #if val
      end

      if ref.respond_to? :description
        val = ref.attribute(:description).to_s
        return BUFFER + val unless val.empty?
      end

      if ref.respond_to? :id
        return " id=#{ref.attribute(:identifier)}"
      end

      # @todo should we have other fallbacks?
      return klass
    end

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
    def to_s
      arrow = style ? style : 'none'
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

  ##
  # Exploit the ordering of a breadth-first enumeration to simplify the
  # creation of edges for the graph. This only works because the UI
  # hiearchy is a simple tree.
  #
  # @return [Array<Accessibility::Graph::Node>]
  attr_reader :edge_queue

  # @param [AX::Element]
  def initialize root
    root_node   = Node.new(root)
    @nodes      = [root_node]
    @edges      = []
    @edge_queue = []
    root.size_of(:children).times do
      @edge_queue << root_node
    end
  end

  ##
  # Construct the list of nodes and edges for the graph.
  #
  # The secret sauce is that we create an edge queue to exploit the
  # breadth first ordering of the enumerator, which makes building the
  # edges very easy.
  def build!
    Accessibility::Enumerators::BreadthFirst.new(nodes.last.ref).each do |element|
      node   = Node.new(element)
      nodes << node
      edges << Edge.new(node, edge_queue.shift)

      next unless element.respond_to? :children
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
    graph << edges.map { |edge| "#{edge.to_s}\n" }.join
    graph << "}\n"
  end

end
