require "open-uri"

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
    end
    
    def configure_paths(config=root_config)
      
    end
    
    def generate_xpath( property_info, opts={})
      prefix = "oxns"
      path = property_info[:path]
      template = "//#{prefix}:#{path}"
      predicates = []   
      default_content_path = property_info.has_key?(:default_content_path) ? property_info[:default_content_path] : ""
        
      # Skip everything if a template was provided
      if opts.has_key?(:template)
        template = eval('"' + opts[:template] + '"')
      else
        # Apply variations
        if opts.has_key?(:variations)
          opts[:variations][:attributes].each_pair do |attr_name, attr_value|
            predicates << "@#{attr_name}=\"#{attr_value}\""
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
            constraint_path = opts[:constraints][:path]
            arguments_for_contains_function << "#{prefix}:#{constraint_path}"
          
            opts[:constraints][:attributes].each_pair do |attr_name, attr_value|
              constraint_predicates << "@#{attr_name}=\"#{attr_value}\""
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
    
    private :file_from_url
    
    
    
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
  
  def validate
    self.class.validate(self)
  end

end