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
    
    # Generates accessors from the object's @properties hash.
    # If no properties have been declared, it doesn't do anything.
    def generate_accessors_from_properties
      if self.properties.nil? || self.properties.empty?
        return nil
      end
      @accessors ||= {}
      # Skip the :unresolved portion of the properties hash
      accessorizables = self.properties.dup
      accessorizables.delete(:unresolved)
      accessorizables.each_pair do |property_ref, property_info|
        insert_accessor_from_property(property_ref, property_info)
      end
    end
    
    # Recurses through a property's info and convenience methods, adding accessors as necessary
    def insert_accessor_from_property(property_ref, property_info, parent_names=[])
      insert_accessor(property_ref,{:relative_xpath => property_info[:xpath_relative], :children=>[]}, parent_names)
      property_info.fetch(:convenience_methods,{}).each_pair do |cm_name, cm_info|
        insert_accessor_from_property(cm_name, cm_info, parent_names+[property_ref] )
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
      if pointers.first.kind_of?(String)
        return pointers.first
      end
      
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
        
        # Return nil if there is no accessor info to work with
        if accessor_info.nil? then return nil end
                
        relative_path = accessor_info[:relative_xpath]
        
        if relative_path.kind_of?(Hash)
          if relative_path.has_key?(:attribute)
            relative_path = "@"+relative_path[:attribute]
          end
        else
        
          unless index.nil?
            relative_path = add_node_index_predicate(relative_path, index)
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
    
    def accessor_constrained_xpath(pointers, constraint)
      constraint_function = "contains(., \"#{constraint}\")"
      xpath = self.accessor_xpath(*pointers)
      xpath = self.add_predicate(xpath, constraint_function)
    end
    
    # Adds xpath xpath node index predicate to the end of your xpath query
    # Example: 
    # add_node_index_predicate("//oxns:titleInfo",0)
    #   => "//oxns:titleInfo[1]"
    #
    # add_node_index_predicate("//oxns:titleInfo[@lang=\"finnish\"]",0)
    #   => "//oxns:titleInfo[@lang=\"finnish\"][1]"
    def add_node_index_predicate(xpath_query, array_index_value)
      modified_query = xpath_query.dup
      modified_query << "[#{array_index_value + 1}]"
    end
    
    # Adds xpath:position() method call to the end of your xpath query
    # Examples: 
    #
    # add_position_predicate("//oxns:titleInfo",0)
    # => "//oxns:titleInfo[position()=1]"
    #
    # add_position_predicate("//oxns:titleInfo[@lang=\"finnish\"]",0)
    # => "//oxns:titleInfo[@lang=\"finnish\" and position()=1]"
    def add_position_predicate(xpath_query, array_index_value)
      position_function = "position()=#{array_index_value + 1}"
      self.add_predicate(xpath_query, position_function)
    end
    
    def add_predicate(xpath_query, predicate)
      modified_query = xpath_query.dup
      # if xpath_query.include?("]")
      if xpath_query[xpath_query.length-1..xpath_query.length] == "]"
        modified_query.insert(xpath_query.rindex("]"), " and #{predicate}")
      else
        modified_query << "[#{predicate}]"
      end
      return modified_query
    end
    
    def accessor_generic_name(*pointers)
      pointers_to_flat_array(pointers, false).join("_")
    end
    
    def accessor_hierarchical_name(*pointers)
      pointers_to_flat_array(pointers, true).join("_")
    end
    
    def pointers_to_flat_array(pointers, include_indices=true)
      OM.pointers_to_flat_array(pointers, include_indices)
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
    if xpath.nil?
      return nil
    else
      return ng_xml.xpath(xpath, ox_namespaces) 
    end   
  end
  
end