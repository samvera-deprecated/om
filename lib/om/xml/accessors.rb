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
    def accessor_info(*args)
      # Ignore any nodeset indexes in the args array
      keys = args.select {|x| !x.kind_of?(Integer) }
      info = @accessors
      keys.each do |k|
        unless keys.index(k) == 0
          info = info.fetch(:children, nil)
          if info.nil?
            debugger
            return nil
          end
        end
        
        info = info.fetch(k, nil)
        if info.nil?
          return nil
        end
      end
      return info
    end
    
    
    def accessor_xpath(*args)
      keys = even_values(args)
      indices = odd_values(args)
      xpath = "//"
      keys.each do |k|
        key_index = keys.index(k)
        accessor_info = accessor_info(*keys[0..key_index])
        relative_path = accessor_info[:relative_xpath]
        
        if relative_path.kind_of?(Hash)
          if relative_path.has_key?(:attribute)
            relative_path = "@"+relative_path[:attribute]
          end
        else
        
          if indices[key_index]
            add_position_predicate!(relative_path, indices[key_index])
          end
        
          if accessor_info.has_key?(:default_content_path)
            relative_path << "/"+accessor_info[:default_content_path]
          end
        
        end
        if key_index > 0
          relative_path.insert(0, "/")
        end
        xpath << relative_path 
      end
      
      return xpath
    end
    
    def add_position_predicate!(xpath_query, array_index_value)
      position_function = "position()=#{array_index_value + 1}"
      
      if xpath_query.include?("]")
        xpath_query.insert(xpath_query.rindex("]"), " and #{position_function}")
      else
        xpath_query << "[#{position_function}]"
      end
    end
    
    def odd_values(array)
      array.values_at(* array.each_index.select {|i| i.odd?})
    end
    def even_values(array)
      array.values_at(* array.each_index.select {|i| i.even?})
    end
  end
  
  # Instance Methods -- These methods will be available on instances of OX classes (ie. the actual xml documents)
  
  def self.included(klass)
    klass.extend(ClassMethods)
    klass.send(:include, OX::PropertyValuesHelper)
  end
  
  # *args Variable length array of values in format [:accessor_name, index, :accessor_name ...]
  # example: [:person, 1, :first_name]
  # Currently, indexes must be integers.
  def retrieve(*args)
    xpath = self.class.accessor_xpath(*args)    
    ng_xml.xpath(xpath, "oxns"=>"http://www.loc.gov/mods/v3")    
  end
  
end