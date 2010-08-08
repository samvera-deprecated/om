module OM::XML::MapperXpathGenerator
  
  def self.generate_relative_xpath(mapper)
    template = ""
    predicates = []
    unless mapper.namespace_prefix.nil?
      template << mapper.namespace_prefix + ":"
    end
    
    unless mapper.attributes.nil?
      mapper.attributes.each_pair do |attr_name, attr_value|
        predicates << "@#{attr_name}=\"#{attr_value}\""
      end
    end
    
    template << mapper.path
    
    unless predicates.empty? 
      template << "["+ delimited_list(predicates, " and ")+"]"
    end
    
    return template
  end
  
  def self.generate_absolute_xpath(mapper)
    relative = generate_relative_xpath(mapper)
    return "//#{relative}"
  end
  
  def self.generate_constrained_xpath(mapper)
    absolute = generate_absolute_xpath(mapper)
    constraint_predicates = []
    
    arguments_for_contains_function = []

    unless mapper.default_content_path.nil?
      default_content_path = property_info[:default_content_path]
      arguments_for_contains_function << "#{prefix}:#{default_content_path}"
    end
    # elsif opts[:constraints].has_key?(:path)
    #   constraints_path_arg = opts[:constraints][:path]
    #   if constraints_path_arg.kind_of?(Hash)
    #     if constraints_path_arg.has_key?(:attribute)
    #       constraint_path = "@"+constraints_path_arg[:attribute]
    #     end
    #   else
    #    constraint_path = "#{prefix}:#{constraints_path_arg}"
    #   end
    #   if opts.has_key?(:subelement_of) && opts[:constraints].has_key?(:default_content_path)
    #     # constraint_path = "#{prefix}:#{opts[:constraints][:path]}"
    #       constraint_path << "/#{prefix}:#{opts[:constraints][:default_content_path]}" 
    #   end
    #   arguments_for_contains_function << constraint_path
    #   
    #   if opts[:constraints].has_key?(:attributes) && opts[:constraints][:attributes].kind_of?(Hash)
    #     opts[:constraints][:attributes].each_pair do |attr_name, attr_value|
    #       constraint_predicates << "@#{attr_name}=\"#{attr_value}\""
    #     end
    #   end    
      # unless constraint_predicates.empty?
      #   arguments_for_contains_function.last << "[#{delimited_list(constraint_predicates)}]"
      # end
    
    arguments_for_contains_function << "\":::constraint_value:::\""
  
    contains_function = "contains(#{delimited_list(arguments_for_contains_function)})"
        
    return add_predicate(absolute, contains_function)
  end
    
  def self.generate_xpath(mapper, type)
    case type
    when :relative
      self.generate_relative_xpath(mapper)
    when :absolute
      self.generate_absolute_xpath(mapper)
    when :constrained
      self.generate_constrained_xpath(mapper)
    end
  end
  
  def self.delimited_list( values_array, delimiter=", ")
    result = values_array.collect{|a| a + delimiter}.to_s.chomp(delimiter)
  end
  
  # Adds xpath xpath node index predicate to the end of your xpath query
  # Example: 
  # add_node_index_predicate("//oxns:titleInfo",0)
  #   => "//oxns:titleInfo[1]"
  #
  # add_node_index_predicate("//oxns:titleInfo[@lang=\"finnish\"]",0)
  #   => "//oxns:titleInfo[@lang=\"finnish\"][1]"
  def self.add_node_index_predicate(xpath_query, array_index_value)
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
  def self.add_position_predicate(xpath_query, array_index_value)
    position_function = "position()=#{array_index_value + 1}"
    self.add_predicate(xpath_query, position_function)
  end
  
  def self.add_predicate(xpath_query, predicate)
    modified_query = xpath_query.dup
    # if xpath_query.include?("]")
    if xpath_query[xpath_query.length-1..xpath_query.length] == "]"
      modified_query.insert(xpath_query.rindex("]"), " and #{predicate}")
    else
      modified_query << "[#{predicate}]"
    end
    return modified_query
  end

end