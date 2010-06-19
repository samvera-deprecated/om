module OX::AccessorHelper
  
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
  end
  
end