class OM::XML::Mapper
  attr_accessor :name, :xpath, :xpath_constrained, :xpath_relative, :path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix
  attr_accessor :children, :ancestors, :internal_xml
  def initialize(name, opts={})
    opts = {:namespace_prefix=>"oxns", :ancestors=>[], :children=>[]}.merge(opts)
    [:children, :ancestors,:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |accessor_name|
      instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )     
    end
    @name = name
    if @path.nil?
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
    return new_mapper
  end
  
  def generate
    self.update_xpath_values
    return self
  end
  
  def regenerate
    self.generate
  end
  
  #  insert the mapper into the given parent
  def set_parent(parent_mapper)
    parent_mapper.children << self
    @ancestors << parent_mapper
  end
  
  #  insert the given mapper into the current mappers children
  def add_child(child_mapper)
    child_mapper.ancestors << self
    @children << child_mapper    
  end
  
  def update_xpath_values
    self.xpath = OM::XML::MapperXpathGenerator.generate_absolute_xpath(self)
    self.xpath_constrained = OM::XML::MapperXpathGenerator.generate_constrained_xpath(self)
    self.xpath_relative = OM::XML::MapperXpathGenerator.generate_relative_xpath(self)
    return self
  end
  
  # private :update_xpath_values
  
end