module OM::XML::Accessors
  
  module ClassMethods
    attr_accessor :accessors
    
    def accessor(accessor_name, opts={})
      @accessors ||= {}
      insert_accessor(accessor_name, opts)
    end
    
    def insert_accessor(accessor_name, accessor_opts, parent_names=[])
      unless accessor_opts.has_key?(:relative_xpath)
        accessor_opts[:relative_xpath] = "oxns:#{accessor_name}"
      end
      
      destination = @accessors
      parent_names.each do |parent_name|
        destination = destination[parent_name][:children]
      end
      
      destination[accessor_name] = accessor_opts
      
      # Recursively call insert_accessor for any children
      if accessor_opts.has_key?(:children)
        children_array = accessor_opts[:children].dup
        accessor_opts[:children] = {}
        children_array.each do |child| 
          if child.kind_of?(Hash)
            child_name =  child.keys.first
            child_opts =  child.values.first
          else
            child_name = child
            child_opts = {}
          end
          insert_accessor(child_name, child_opts, parent_names+[accessor_name] )           
        end
      end
        
    end
    
    # Returns the configuration info for the selected accessor.
    # Ingores any integers in the array (ie. nodeset indices intended for use in other accessor convenience methods)
    def accessor_info(*pointers)
      info = @accessors
      
      # flatten the pointers array, excluding node indices
      pointers = pointers_to_flat_array(pointers, false)
      
      pointers.each do |pointer|
        
        unless pointers.index(pointer) == 0
          info = info.fetch(:children, nil)
          if info.nil?
            return nil
          end
        end
        
        info = info.fetch(pointer, nil)
        if info.nil?
          return nil
        end
      end
      return info
    end
    
    
    def accessor_xpath(*pointers)
      
      keys = []
      xpath = "//"
      pointers.each do |pointer|
        
        if pointer.kind_of?(Hash)
          k = pointer.keys.first
          index = pointer[k]
        else
          k = pointer
          index = nil
        end
        
        keys << k
        
        # key_index = keys.index(k)
        pointer_index = pointers.index(pointer)
        # accessor_info = accessor_info(*keys[0..key_index])
        accessor_info = accessor_info(*keys)        
        relative_path = accessor_info[:relative_xpath]
        
        if relative_path.kind_of?(Hash)
          if relative_path.has_key?(:attribute)
            relative_path = "@"+relative_path[:attribute]
          end
        else
        
          unless index.nil?
            relative_path = add_position_predicate(relative_path, index)
          end
        
          if accessor_info.has_key?(:default_content_path)
            relative_path << "/"+accessor_info[:default_content_path]
          end
        
        end
        if pointer_index > 0
          relative_path = "/"+relative_path
        end
        xpath << relative_path 
      end
      
      return xpath
    end
    
    def add_position_predicate(xpath_query, array_index_value)
      modified_query = xpath_query.dup
      position_function = "position()=#{array_index_value + 1}"
      
      if xpath_query.include?("]")
        modified_query.insert(xpath_query.rindex("]"), " and #{position_function}")
      else
        modified_query << "[#{position_function}]"
      end
      return modified_query
    end
    
    def accessor_generic_name(*pointers)
      pointers_to_flat_array(pointers, false).join("_")
    end
    
    def accessor_hierarchical_name(*pointers)
      pointers_to_flat_array(pointers, true).join("_")
    end
    
    # @pointers pointers array that you would pass into other Accessor methods
    # @include_indices (default: true) if set to false, parent indices will be excluded from the array
    # Converts an array of accessor pointers into a flat array.
    # ie. [{:conference=>0}, {:role=>1}, :text] becomes [:conference, 0, :role, 1, :text]
    #   if include_indices is set to false,
    #     [{:conference=>0}, {:role=>1}, :text] becomes [:conference, :role, :text]
    def pointers_to_flat_array(pointers, include_indices=true)
      flat_array = []
      pointers.each do |pointer|
        if pointer.kind_of?(Hash)
          flat_array << pointer.keys.first
          if include_indices 
            flat_array << pointer.values.first
          end
        else
          flat_array << pointer
        end
      end
      return flat_array
    end
    
  end
  
  # Instance Methods -- These methods will be available on instances of OM classes (ie. the actual xml documents)
  
  def self.included(klass)
    klass.extend(ClassMethods)
  end
  
  # *pointers Variable length array of values in format [:accessor_name, :accessor_name ...] or [{:accessor_name=>index}, :accessor_name ...]
  # example: [:person, 1, :first_name]
  # Currently, indexes must be integers.
  def retrieve(*pointers)
    xpath = self.class.accessor_xpath(*pointers)    
    ng_xml.xpath(xpath, "oxns"=>"http://www.loc.gov/mods/v3")    
  end
  
end