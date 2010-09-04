class OM::XML::Term
  
  class Builder
    attr_accessor :name, :settings, :children, :terminology_builder
    
    def initialize(name, terminology_builder=nil)
      @name = name.to_sym
      @terminology_builder = terminology_builder
      @settings = {:required=>false, :data_type=>:string}
      @children = {}
    end
    
    def add_child(child)
      @children[child.name] = child
    end
    
    def retrieve_child(child_name)
      child = @children.fetch(child_name, nil)
    end
    
    def lookup_refs(nodes_visited=[])
      result = []
      if @settings[:ref]
        # Fail if we do not have terminology builder
        if self.terminology_builder.nil?
          raise "Cannot perform lookup_ref for the #{self.name} builder.  It doesn't have a reference to any terminology builder"
        end
        begin
          target = self.terminology_builder.retrieve_term_builder(*@settings[:ref])
        rescue OM::XML::Terminology::BadPointerError
          # Clarify message on BadPointerErrors
          raise OM::XML::Terminology::BadPointerError, "#{self.name} refers to a Term Builder that doesn't exist.  The bad pointer is #{@settings[:ref].inspect}"
        end
        
        # Fail on circular references and return an intelligible error message
        if nodes_visited.contains?(target)
          nodes_visited << self
          nodes_visited << target
          trail = ""
          nodes_visited.each_with_index do |node, z|
            trail << node.name.inspect
            unless z == nodes_visited.length-1
              trail << " => "
            end
          end
          raise OM::XML::Terminology::CircularReferenceError, "Circular reference in Terminology: #{trail}"
        end
        result << target
        result.concat( target.lookup_refs(nodes_visited << self) )
      end
      return result
    end
    
    def resolve_refs!
    end
    
    # def resolve_settings(nodes_visited = {})
    #   if @settings[:ref]
    #     fail if we do not have terminology builder
    #     fail with circular ref error if nodes_visited[self]
    #     nodes_visited[self] = true
    #     @settings = self.terminology_builder.find(@settings[:ref]).resolve_settings(nodes_visited).merge(@settings)
    #     @settings.delete :ref
    #   end
    #   @settings
    # end
    
    # Builds a new OM::XML::Term based on the Builder object's current settings
    # If no path has been provided, uses the Builder object's name as the term's path
    # Recursively builds any children, appending the results as children of the Term that's being built.
    def build
      term = OM::XML::Term.new(self.name)
      self.settings.each do |name, values|  
        if term.respond_to?(name.to_s+"=")
          term.instance_variable_set("@#{name}", values)
        end
      end
      @children.each_value do |child|
        term.add_child child.build
      end
      term.generate_xpath_queries!
      return term
    end
    
    # Any unknown method calls will add an entry to the settings hash and return the current object
    def method_missing method, *args, &block 
      if args.length == 1
        args = args.first
      end
      @settings[method] = args
      return self
    end
  end
  
  attr_accessor :name, :xpath, :xpath_constrained, :xpath_relative, :path, :index_as, :required, :data_type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix, :is_root_term
  attr_accessor :children, :ancestors, :internal_xml, :terminology
  def initialize(name, opts={})
    opts = {:namespace_prefix=>"oxns", :ancestors=>[], :children=>{}}.merge(opts)
    [:children, :ancestors,:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |accessor_name|
      instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )     
    end
    @name = name
    if @path.nil? || @path.empty?
      @path = name.to_s
    end
  end
  
  def self.from_node(mapper_xml)    
    name = mapper_xml.attribute("name").text.to_sym
    attributes = {}
    mapper_xml.xpath("./attribute").each do |a|
      attributes[a.attribute("name").text.to_sym] = a.attribute("value").text
    end
    new_mapper = self.new(name, :attributes=>attributes)
    [:index_as, :required, :type, :variant_of, :path, :default_content_path, :namespace_prefix].each do |accessor_name|
      attribute =  mapper_xml.attribute(accessor_name.to_s)
      unless attribute.nil?
        new_mapper.instance_variable_set("@#{accessor_name}", attribute.text )      
      end     
    end
    new_mapper.internal_xml = mapper_xml
    
    mapper_xml.xpath("./mapper").each do |child_node|
      child = self.from_node(child_node)
      new_mapper.add_child(child)
    end
    
    return new_mapper
  end
  
  # crawl down into mapper's children hash to find the desired mapper
  # ie. @test_mapper.retrieve_mapper(:conference, :role, :text)
  def retrieve_mapper(*pointers)
    children_hash = self.children
    pointers.each do |p|
      if children_hash.has_key?(p)
        target = children_hash[p]
        if pointers.index(p) == pointers.length-1
          return target
        else
          children_hash = target.children
        end
      else
        return nil
      end
    end
    return target
  end
  
  #  insert the mapper into the given parent
  def set_parent(parent_mapper)
    parent_mapper.children[@name] = self
    @ancestors << parent_mapper
  end
  
  #  insert the given mapper into the current mappers children
  def add_child(child_mapper)
    child_mapper.ancestors << self
    @children[child_mapper.name.to_sym] = child_mapper    
  end
  
  def retrieve_child(child_name)
    child = @children.fetch(child_name, nil)
  end
  
  def parent
    ancestors.last
  end
  
  def root_term?
    @is_root_term
  end
  
  def xpath_absolute
    @xpath
  end
  
  # Generates absolute, relative, and constrained xpaths for the term, setting xpath, xpath_relative, and xpath_constrained accordingly.
  # Also triggers update_xpath_values! on all child nodes, as their absolute paths rely on those of their parent nodes.
  def generate_xpath_queries!
    self.xpath = OM::XML::TermXpathGenerator.generate_absolute_xpath(self)
    self.xpath_constrained = OM::XML::TermXpathGenerator.generate_constrained_xpath(self)
    self.xpath_relative = OM::XML::TermXpathGenerator.generate_relative_xpath(self)
    self.children.each_value {|child| child.generate_xpath_queries! }
    return self
  end
  
  # private :update_xpath_values
  
end