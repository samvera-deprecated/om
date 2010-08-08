class OM::XML::Mapper
  attr_accessor :xpath, :xpath_constrained, :xpath_relative, :path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix
  
  def initialize(name, opts={})
    opts = {:namespace_prefix=>"oxns"}.merge(opts)
    [:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path, :namespace_prefix].each do |accessor_name|
      instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )     
    end
  end
  
  #:path, :index_as, :required, :type, :variant_of, :path, :attributes, :default_content_path
end