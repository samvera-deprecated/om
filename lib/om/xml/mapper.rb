class OM::XML::Mapper
  attr_accessor :name, :xpath, :xpath_constrained, :xpath_relative, :path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix
  
  def initialize(name, opts={})
    opts = {:namespace_prefix=>"oxns"}.merge(opts)
    [:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |accessor_name|
      instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )     
    end
    self.name = name
    if self.path.nil?
      self.path = name.to_s
    end
  end
  
  def generate
    self.update_xpath_values
    return self
  end
  
  def update_xpath_values
    self.xpath = OM::XML::MapperXpathGenerator.generate_absolute_xpath(self)
    self.xpath_constrained = OM::XML::MapperXpathGenerator.generate_constrained_xpath(self)
    self.xpath_relative = OM::XML::MapperXpathGenerator.generate_relative_xpath(self)
    return self
  end
  
  #:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path
end