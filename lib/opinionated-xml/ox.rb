require "open-uri"
require "logger"

module OX
  
  # Class Methods -- These methods will be available on classes that include OX (ie. the OX MODS class)
  
  module ClassMethods
    
    attr_accessor :root_property_ref, :root_config, :ox_namespaces, :schema_url
    attr_writer :schema_file
    attr_reader :properties
    
    def root_property( property_ref, path, namespace, opts={})
      # property property_ref, path, opts.merge({:path=>path, :ref=>property_ref})
      @root_config = opts.merge({:namespace=>namespace, :path=>path, :ref=>property_ref})
      @root_property_ref = property_ref
      @ox_namespaces = {'oxns'=>root_config[:namespace]}
      @schema_url = opts[:schema]
    end
    
    def property( property_ref, opts={})
      @properties ||= {}
      @properties[property_ref] = opts.merge({:ref=>property_ref})
      configure_property @properties[property_ref]
      configure_paths @properties[property_ref]
    end
    
    def configure_property(prop_hash=root_config)
      if prop_hash.has_key?(:variant_of)
        properties[prop_hash[:ref]] = properties[prop_hash[:variant_of]].deep_copy.merge(prop_hash)
      end
      if !prop_hash.has_key?(:convenience_methods)
        prop_hash[:convenience_methods] = {}
      end
    end
    
    # Generates appropriate xpath queries for a property described by the given hash
    # putting the results into the hash under keys like :xpath and :xpath_constrained
    # This is also done recursively for all subelements and convenience methods described in the hash.
    def configure_paths(prop_hash=root_config)
      prop_hash[:path] ||= ""
      # prop_hash[:path] = Array( prop_hash[:path] )
      xpath_opts = {}
      
      if prop_hash.has_key?(:variant_of)
        xpath_opts[:variations] = prop_hash
      end
      
      xpath_constrained_opts = xpath_opts.merge({:constraints=>:default})
      
      relative_xpath = generate_xpath(prop_hash, xpath_opts.merge(:relative=>true))
      # prop_hash[:xpath] = generate_xpath(prop_hash, xpath_opts)
      prop_hash[:xpath] = "//#{relative_xpath}"
      prop_hash[:xpath_relative] = relative_xpath
      prop_hash[:xpath_constrained] = generate_xpath(prop_hash, xpath_constrained_opts).gsub('"', '\"')
      
      prop_hash[:convenience_methods].each_pair do |cm_name, cm_props|
        cm_xpath_relative_opts = cm_props.merge(:variations => cm_props, :relative=>true)
        cm_constrained_opts = xpath_opts.merge(:constraints => cm_props)
        
        cm_relative_xpath = generate_xpath(cm_props, cm_xpath_relative_opts)
        prop_hash[:convenience_methods][cm_name][:xpath_relative] = cm_relative_xpath
        # prop_hash[:convenience_methods][cm_name][:xpath] = generate_xpath(cm_xpath_hash, cm_xpath_opts)
        prop_hash[:convenience_methods][cm_name][:xpath] = prop_hash[:xpath] + "/" + cm_relative_xpath
        prop_hash[:convenience_methods][cm_name][:xpath_constrained] = generate_xpath(prop_hash, cm_constrained_opts).gsub('"', '\"')
      end
      
      if prop_hash.has_key?(:subelements) 
        prop_hash[:subelements].each do |se|
          configure_subelement_paths(se, prop_hash, xpath_opts)
        end
      end
      
      if properties[:unresolved].has_key?(prop_hash[:ref])
        ref = prop_hash[:ref]
        properties[:unresolved][ref].each do |parent_prop_hash|
          logger.debug "Resolving #{ref} subelement for #{parent_prop_hash[:ref]} property"
          configure_subelement_paths(ref, parent_prop_hash, xpath_opts)
        end
        properties[:unresolved].delete(ref)
      end

    end
    
    def configure_subelement_paths(se, parent_prop_hash, parent_xpath_opts)
      # se_xpath_opts = parent_xpath_opts.merge(:subelement_of => parent_prop_hash[:ref])
      se_xpath_opts = parent_xpath_opts
      
      if parent_prop_hash.has_key?(:variant_of)
        se_xpath_opts[:variations] = parent_prop_hash
      end
      
      if se.instance_of?(String)
         
        se_relative_xpath = generate_xpath({:path=>se}, :relative=>true)
        se_xpath = parent_prop_hash[:xpath] + "/" + se_relative_xpath
        
        se_xpath_constrained_opts = se_xpath_opts.merge({:constraints=>{:path=>se}})
        se_xpath_constrained = generate_xpath(parent_prop_hash, se_xpath_constrained_opts)
        
      elsif se.instance_of?(Symbol) 
        
        if properties.has_key?(se)
          se_props = properties[se]
          
          se_relative_xpath = se_props[:xpath_relative]
          se_xpath = parent_prop_hash[:xpath] + "/" + se_relative_xpath
          
          se_xpath_constrained_opts = parent_xpath_opts.merge(:constraints => se_props, :subelement_of => parent_prop_hash[:ref])        
          se_xpath_constrained = generate_xpath(parent_prop_hash, se_xpath_constrained_opts)
          
        else
          properties[:unresolved] ||= {}
          properties[:unresolved][se] ||= []
          properties[:unresolved][se] << parent_prop_hash
          logger.debug("Added #{se.inspect} to unresolved properties with parent #{parent_prop_hash[:ref]}")
          se_xpath = ""
          se_xpath_constrained = ""
          se_relative_xpath = ""
        end                
      else
        logger.info("failed to generate path for #{se.inspect}")
        se_xpath = ""
        se_xpath_constrained = ""
      end

      properties[ parent_prop_hash[:ref] ][:convenience_methods][se.to_sym] = {:xpath=>se_xpath, :xpath_constrained=>se_xpath_constrained.gsub('"', '\"'), :xpath_relative=>se_relative_xpath}  

    end
    
    def generate_xpath( property_info, opts={})
      prefix = "oxns"
      property_info[:path] ||= "" 
      path = property_info[:path]
      path_array = Array( path )
      template = ""
      template << "//" unless opts[:relative]
      template << "#{prefix}:"
      template << delimited_list(path_array, "/#{prefix}:")

      predicates = []   
      default_content_path = property_info.has_key?(:default_content_path) ? property_info[:default_content_path] : ""
      subelement_path_parts = []
      
      # Skip everything if a template was provided
      if opts.has_key?(:template)
        template = eval('"' + opts[:template] + '"')
      else
        # Apply variations
        if opts.has_key?(:variations)
          if opts[:variations].has_key?(:attributes)
            opts[:variations][:attributes].each_pair do |attr_name, attr_value|
              predicates << "@#{attr_name}=\"#{attr_value}\""
            end
          end
          if opts[:variations].has_key?(:subelement_path) 
            if opts[:variations][:subelement_path].instance_of?(Array)
              opts[:variations][:subelement_path].each do |se_path|
                subelement_path_parts << "#{prefix}:#{se_path}"  
              end
            else
              subelement_path_parts << "#{prefix}:#{opts[:variations][:subelement_path]}"  
            end
          end
        end
      
        # Apply constraints
        if opts.has_key?(:constraints)  
          arguments_for_contains_function = []
          if opts[:constraints] == :default
            if property_info.has_key?(:default_content_path)
              default_content_path = property_info[:default_content_path]
              arguments_for_contains_function << "#{prefix}:#{default_content_path}"
            end
          elsif opts[:constraints].has_key?(:path)
            constraint_predicates = []
            if opts.has_key?(:subelement_of)
              constraint_path = "#{prefix}:#{opts[:constraints][:path]}"
              if opts[:constraints].has_key?(:default_content_path)
                constraint_path << "/#{prefix}:#{opts[:constraints][:default_content_path]}"
              end 
            else
             constraint_path = "#{prefix}:#{opts[:constraints][:path]}"
            end
            arguments_for_contains_function << constraint_path
            
            if opts[:constraints].has_key?(:attributes) && opts[:constraints][:attributes].kind_of?(Hash)
              opts[:constraints][:attributes].each_pair do |attr_name, attr_value|
                constraint_predicates << "@#{attr_name}=\"#{attr_value}\""
              end
            end
          
            unless constraint_predicates.empty?
              arguments_for_contains_function.last << "[#{delimited_list(constraint_predicates)}]"
            end
          
          end
          arguments_for_contains_function << "\":::constraint_value:::\""
        
          predicates << "contains(#{delimited_list(arguments_for_contains_function)})"
        
        end
            
        unless predicates.empty? 
          template << "["
          template << delimited_list(predicates, " and ")
          template << "]"
        end
        
        unless subelement_path_parts.empty?
          subelement_path_parts.each {|path_part| template << "/#{path_part}"}
        end
      end
      
      # result = eval( '"' + template + '"' )
      return template.gsub( /:::(.*?):::/ ) { '#{'+$1+'}' }
    end
    
    ##
    # Validation Support
    ##
    
    # Validate the given document against the Schema provided by the root_property for this class
    def validate(doc)
      schema.validate(doc).each do |error|
          puts error.message
      end
    end
    
    # Retrieve the Nokogiri Schema for this class
    def schema
      @schema ||= Nokogiri::XML::Schema(schema_file.read)
    end
    
    # Retrieve the schema file for this class
    # If the schema file is not already set, it will be loaded from the schema url provided in the root_property configuration for the class
    def schema_file
      @schema_file ||= file_from_url(schema_url)
    end
    
    # Retrieve file from a url (used by schema_file method to retrieve schema file from the schema url)
    def file_from_url( url )
      # parsed_url = URI.parse( url )
      # 
      # if parsed_url.class != URI::HTTP 
      #   raise "Invalid URL.  Could not parse #{url} as a HTTP url."
      # end
      
      begin
        file = open( url )
        return file
      rescue OpenURI::HTTPError => e
        raise "Could not retrieve file from #{url}. Error: #{e}"
      rescue Exception => e  
        raise "Could not retrieve file from #{url}. Error: #{e}"
      end
    end
    
    def delimited_list( values_array, delimiter=", ")
      result = values_array.collect{|a| a + delimiter}.to_s.chomp(delimiter)
    end
    
    def logger      
      @logger ||= defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new(STDOUT)
    end
    
    private :file_from_url
    
    
    
  end
  
  # Instance Methods -- These methods will be available on instances of OX classes (ie. the actual xml documents)
  
  # Applies the property's corresponding xpath query, returning the result Nokogiri::XML::NodeSet
  def lookup( property_ref, query_opts={}, opts={} )
    if self.class.properties.has_key?(property_ref)
      if query_opts.kind_of?(String)
        constraint_value = query_opts
        xpath_template = self.class.properties[property_ref][:xpath_constrained]
        constrained_query = eval( '"' + xpath_template + '"' )
        result = xpath(constrained_query, ox_namespaces)
      elsif !query_opts.empty?       
        query_opts.each_pair do |k, v|
          constraint_value = v
          xpath_template = self.class.properties[property_ref][:convenience_methods][k][:xpath_constrained]
          constrained_query = eval( '"' + xpath_template + '"' )          
          result = xpath(constrained_query, ox_namespaces)
        end
      else 
        result = xpath(self.class.properties[property_ref][:xpath], ox_namespaces)
      end
    else
      result = []
    end
    return result
  end  
  
  # Returns a hash combining the current documents namespaces (provided by nokogiri) and any namespaces that have been set up by your class definiton.
  # Most importantly, this matches the 'oxns' namespace to the namespace you provided in your root property config
  def ox_namespaces
    @ox_namespaces ||= namespaces.merge(self.class.ox_namespaces)
  end
  
  def validate
    self.class.validate(self)
  end

end