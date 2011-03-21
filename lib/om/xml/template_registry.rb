class OM::XML::Template

  def initialize(namespaces = {})
    @templates = {}
    @namespaces = namespaces
  end

  def namespaces
    if @namespaces.is_a?(Proc)
      @namespaces.call
    else
      @namespaces
    end
  end
  
  def register(node_type, &block)
    unless node_type.is_a?(Symbol)
      raise TypeError, "Registered node type must be a Symbol (e.g., :person)"
    end
  
    @templates[node_type] = block
    node_type
  end

  def unregister(node_type)
    @templates.delete(node_type)
    node_type
  end

  def has_node_type?(node_type)
    @templates.has_key?(node_type)
  end

  def node_types
    @templates.keys
  end

  def add_template(parent_node, node_type, *args)
    proc = @templates[node_type]
    if proc.nil?
      raise NameError, "Unknown node type: #{node_type.to_s}"
    end
    builder = Nokogiti::XML::Builder.with(parent_node) do |xml|
      proc.call(xml,*args)
    end
    return parent_node
  end

  def build_template(node_type,*args)
    namespace_attrs = namespaces.inject({}) { |result,ns| 
      (prefix,href) = ns
      result[["xmlns",prefix].compact.join(':')] = href
      result
    }
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.root(namespace_attrs)
    end
    root = builder.doc.root
    add_template(root, node_type, *args)
    elements = root.elements
    if elements.length > 0
      elements.first.remove
    else
      nil
    end
  end

  def methods
    super + @templates.keys.collect { |k| k.to_s }
  end

  def method_missing(sym,*args)
    if @templates.has_key?(sym)
      build_template(sym,*args)
    else
      super(sym,*args)
    end
  end

end
