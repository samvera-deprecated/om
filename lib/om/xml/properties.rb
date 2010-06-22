module OM::XML::Properties
  
  attr_accessor :ng_xml
  
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    attr_accessor :root_property_ref, :root_config, :ox_namespaces
    attr_reader :properties
    
    def root_property( property_ref, path, namespace, opts={})
      property property_ref, opts.merge({:path=>path, :ref=>property_ref})
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
      
      if properties.fetch(:unresolved, {}).has_key?(prop_hash[:ref])
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
      new_se_props = {}
      if parent_prop_hash.has_key?(:variant_of)
        se_xpath_opts[:variations] = parent_prop_hash
      end
      
      if se.instance_of?(String)
        
        new_se_props[:path] = se
        new_se_props[:xpath_relative] = generate_xpath({:path=>se}, :relative=>true)
        new_se_props[:xpath] = parent_prop_hash[:xpath] + "/" + new_se_props[:xpath_relative]
        se_xpath_constrained_opts = se_xpath_opts.merge({:constraints=>{:path=>se}})
        new_se_props[:xpath_constrained] = generate_xpath(parent_prop_hash, se_xpath_constrained_opts)
        
      elsif se.instance_of?(Symbol) 
        
        if properties.has_key?(se)
          
          se_props = properties[se]
          
          new_se_props = se_props.deep_copy
          # new_se_props[:path] = se_props[:path]
          # new_se_props[:xpath_relative] = se_props[:xpath_relative]
          new_se_props[:xpath] = parent_prop_hash[:xpath] + "/" + new_se_props[:xpath_relative] 
          se_xpath_constrained_opts = parent_xpath_opts.merge(:constraints => se_props, :subelement_of => parent_prop_hash[:ref])        
          new_se_props[:xpath_constrained] = generate_xpath(parent_prop_hash, se_xpath_constrained_opts)
                
        else
          properties[:unresolved] ||= {}
          properties[:unresolved][se] ||= []
          properties[:unresolved][se] << parent_prop_hash
          logger.debug("Added #{se.inspect} to unresolved properties with parent #{parent_prop_hash[:ref]}")
        end                
      else
        logger.info("failed to generate path for #{se.inspect}")
        se_xpath = ""
        se_xpath_constrained = ""
      end

      if new_se_props.has_key?(:xpath_constrained)
        new_se_props[:xpath_constrained].gsub!('"', '\"')
      end
      
      properties[ parent_prop_hash[:ref] ][:convenience_methods][se.to_sym] = new_se_props  

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
    
    #
    # Convenience Methods for Retrieving Generated Info
    #
    
    def xpath_query_for( property_ref, query_opts={}, opts={} )

      if property_ref.instance_of?(String)
        xpath_query = property_ref
      else
        property_info = property_info_for( property_ref )

        if !property_info.nil?
          if query_opts.kind_of?(String)
            constraint_value = query_opts
            xpath_template = property_info[:xpath_constrained]
            xpath_query = eval( '"' + xpath_template + '"' )
          elsif query_opts.kind_of?(Hash) && !query_opts.empty?       
            key_value_pair = query_opts.first 
            constraint_value = key_value_pair.last
            xpath_template = property_info[:convenience_methods][key_value_pair.first][:xpath_constrained]
            xpath_query = eval( '"' + xpath_template + '"' )          
          else 
            xpath_query = property_info[:xpath]
          end
        else
          xpath_query = nil
        end
      end
      return xpath_query
    end

    def property_info_for(property_ref)
      if property_ref.instance_of?(Array) && property_ref.length == 1
        property_ref = property_ref[0]      
      end
      if property_ref.instance_of?(Symbol)
        property_info = properties[property_ref]
      elsif property_ref.kind_of?(Array)
        prop_ref = property_ref[0]
        cm_name = property_ref[1]
        if properties.has_key?(prop_ref)
          property_info = properties[prop_ref][:convenience_methods][cm_name]
        end
      else
        property_info = nil
      end
      return property_info 
    end
    
    
    def delimited_list( values_array, delimiter=", ")
      result = values_array.collect{|a| a + delimiter}.to_s.chomp(delimiter)
    end
    
    
    #
    # Builder Support
    #
    
    def builder_template(property_ref, opts={})
      property_info = property_info_for(property_ref)

      prop_info = property_info.merge(opts) 
      
      if prop_info.nil?
        return nil
      else
        node_options = []
        node_child_template = ""
        if prop_info.has_key?(:default_content_path)
          node_child_options = ["\':::builder_new_value:::\'"]
          node_child_template = " { xml.#{property_info[:default_content_path]}( #{delimited_list(node_child_options)} ) }"
        else
          node_options = ["\':::builder_new_value:::\'"]
        end
        # if opts.has_key?(:attributes) ...
        # ...
        if prop_info.has_key?(:attributes)
          applicable_attributes( prop_info[:attributes] ).each_pair do |k,v|
            node_options << ":#{k}=>\'#{v}\'"
          end
        end
        template = "xml.#{prop_info[:path]}( #{delimited_list(node_options)} )" + node_child_template
        return template.gsub( /:::(.*?):::/ ) { '#{'+$1+'}' }
      end
    end
    
    # @attributes_spec Array or Hash
    # Returns a Hash where all of the values are strings
    # {:type=>"date"} will return {:type=>"date"}
    # {["authority", {:type=>["text","code"]}] will return {:type=>"text"}
    def applicable_attributes(attributes)
      
      if attributes.kind_of?(Hash)
        attributes_hash = attributes
      elsif attributes.kind_of?(Array)
        attributes_hash = {}
        attributes.each do |bute|
          if bute.kind_of?(Hash)
            attributes_hash.merge!(bute)
          end
        end
      end
      
      applicable_attributes = {}
      attributes_hash.each_pair {|k,v| applicable_attributes[k] = condense_value(v) }
      
      
      return applicable_attributes
    end
    
    def condense_value(value)
      if value.kind_of?(Array)
        return value.first
      else
        return value
      end
    end
    
    def logger      
      @logger ||= defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new(STDOUT)
    end
    
    private :applicable_attributes
  end
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def self.included(klass)
    klass.extend(ClassMethods)
  end
  
  # Applies the property's corresponding xpath query, returning the result Nokogiri::XML::NodeSet
  def lookup( property_ref, query_opts={}, opts={} )
    xpath_query = xpath_query_for( property_ref, query_opts, opts )
    
    if xpath_query.nil?
      result = []
    else
      result = ng_xml.xpath(xpath_query, ox_namespaces)
    end
    
    return result
  end  
  
  
  # Returns a hash combining the current documents namespaces (provided by nokogiri) and any namespaces that have been set up by your class definiton.
  # Most importantly, this matches the 'oxns' namespace to the namespace you provided in your root property config
  def ox_namespaces
    @ox_namespaces ||= ng_xml.namespaces.merge(self.class.ox_namespaces)
  end
  
  def xpath_query_for( property_ref, query_opts={}, opts={} )
    self.class.xpath_query_for( property_ref, query_opts, opts )
  end
  
  def property_info_for(property_ref)
    self.class.property_info_for(property_ref)
  end
  
end