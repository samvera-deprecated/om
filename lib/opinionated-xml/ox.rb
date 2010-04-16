module OX
  
  # Class Methods -- These methods will be available on classes that include OX (ie. the OX MODS class)
  
  module ClassMethods
    
    attr_accessor :root_property_ref, :root_config, :ox_namespaces
    
    def root_property( property_ref, path, namespace, opts={})
      @root_config = opts.merge({:namespace=>namespace, :path=>path, :ref=>property_ref})
      @root_property_ref = property_ref
      @ox_namespaces = {'oxns'=>@root_config[:namespace]}
    end
    
    def property( property_ref, path, &block)
    end
    
  end
  
  # Instance Methods -- These methods will be available on instances of OX classes (ie. the actual xml documents)
  
  def lookup( property_ref, opts={} )
    result = []
    return result
  end  
  
  # Returns a hash combining the current documents namespaces (provided by nokogiri) and any namespaces that have been set up by your class definiton.
  # Most importantly, this matches the 'oxns' namespace to the namespace you provided in your root property config
  def ox_namespaces
    @ox_namespaces ||= namespaces.merge(self.class.ox_namespaces)
  end

end