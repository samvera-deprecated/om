module OM::XML::Validation
  extend ActiveSupport::Concern
    
  # Class Methods -- These methods will be available on classes that include this Module 
  
  module ClassMethods
    attr_accessor :schema_url
    attr_writer :schema_file
    
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
    
    private :file_from_url
    
  end
  
  # Instance Methods -- These methods will be available on instances of classes that include this module
  
  def validate
    self.class.validate(self)
  end
    
end
