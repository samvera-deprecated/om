class OM::XML::NamedTermProxy
  
  attr_accessor :proxy_pointer, :name
  
  include OM::TreeNode
  
  def initialize(name, proxy_pointer, opts={})
    opts = {:namespace_prefix=>"oxns", :ancestors=>[], :children=>{}}.merge(opts)
    [:children, :ancestors].each do |accessor_name|
      instance_variable_set("@#{accessor_name}", opts.fetch(accessor_name, nil) )     
    end
    @name = name
    @proxy_pointer = proxy_pointer
  end
  
  def proxied_term
    self.parent.retrieve_term(*self.proxy_pointer)
  end
  
  # do nothing -- this is to prevent errors when the parent term calls generate_xpath_queries! on its children
  def generate_xpath_queries!
    # do nothing
  end
  
  def method_missing
  end
  
  # Any unknown method calls will be proxied to the proxied term
  def method_missing method, *args, &block 
    if args.empty?
      return self.proxied_term.send(method)
    else
      return self.proxied_term.send(method, args)
    end
  end
  
end