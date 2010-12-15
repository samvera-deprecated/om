module OM::XML::TermXpathGenerator
  
  def self.generate_relative_xpath(mapper)
    template = ""
    predicates = []
    
    if mapper.namespace_prefix.nil?
      complete_prefix = ""
    else
      complete_prefix = mapper.namespace_prefix + ":"
    end
    
    if mapper.path.kind_of?(Hash)
      if mapper.path.has_key?(:attribute)
        base_path = "@"+mapper.path[:attribute]
      else
        raise "#{mapper.path} is an invalid path for an OM::XML::Term.  You should provide either a string or {:attributes=>XXX}"
      end
    else
      unless mapper.namespace_prefix.nil?
        template << complete_prefix
      end
      base_path = mapper.path
    end
    template << base_path
    
    unless mapper.attributes.nil?
      mapper.attributes.each_pair do |attr_name, attr_value|
        predicates << "@#{attr_name}=\"#{attr_value}\""
      end
    end
    
    unless predicates.empty? 
      template << "["+ delimited_list(predicates, " and ")+"]"
    end
    
    return template
  end
  
  def self.generate_absolute_xpath(mapper)
    relative = generate_relative_xpath(mapper)
    if mapper.parent.nil?
      return "//#{relative}"
    else
      return mapper.parent.xpath_absolute + "/" + relative
    end
  end
  
  def self.generate_constrained_xpath(mapper)
    if mapper.namespace_prefix.nil?
      complete_prefix = ""
    else
      complete_prefix = mapper.namespace_prefix + ":"
    end
    
    absolute = generate_absolute_xpath(mapper)
    constraint_predicates = []
    
    arguments_for_contains_function = []

    if !mapper.default_content_path.nil?
      arguments_for_contains_function << "#{complete_prefix}#{mapper.default_content_path}"
    end
      
    # If no subelements have been specified to search within, set contains function to search within the current node
    if arguments_for_contains_function.empty?
      arguments_for_contains_function << "."
    end
    
    arguments_for_contains_function << "\":::constraint_value:::\""
  
    contains_function = "contains(#{delimited_list(arguments_for_contains_function)})"

    template = add_predicate(absolute, contains_function)
    return template.gsub( /:::(.*?):::/ ) { '#{'+$1+'}' }.gsub('"', '\"')
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
  
  # Use the given +terminology+ to generate an xpath with (optional) node indexes for each of the term pointers.
  # Ex.  OM::XML::TermXpathGenerator.xpath_with_indexes(my_terminology, {:conference=>0}, {:role=>1}, :text ) 
  #      will yield an xpath similar to this: '//oxns:name[@type="conference"][1]/oxns:role[2]/oxns:roleTerm[@type="text"]'
  def self.generate_xpath_with_indexes(terminology, *pointers)
    if pointers.first.nil?
      root_term = terminology.root_terms.first
      if root_term.nil?
        return "/"
      else
        return root_term.xpath
      end
    end
    
    query_constraints = nil
    
    if pointers.length > 1 && pointers.last.kind_of?(Hash)
      constraints = pointers.pop
      unless constraints.empty?
        query_constraints = constraints
      end 
    end

    if pointers.length == 1 && pointers.first.instance_of?(String)
      return xpath_query = pointers.first
    end
      
    # if pointers.first.kind_of?(String)
    #   return pointers.first
    # end
    
    keys = []
    xpath = "//"

    pointers = OM.destringify(pointers)
    pointers.each_with_index do |pointer, pointer_index|
      
      if pointer.kind_of?(Hash)
        k = pointer.keys.first
        index = pointer[k]
      else
        k = pointer
        index = nil
      end
      
      keys << k
      
      term = terminology.retrieve_term(*keys)  
      # Return nil if there is no term to work with
      if term.nil? then return nil end
      
      # If we've encountered a NamedTermProxy, insert path sections corresponding to 
      # terms corresponding to each entry in its proxy_pointer rather than just the final term that it points to.
      if term.kind_of? OM::XML::NamedTermProxy
        current_location = term.parent.nil? ? term.terminology : term.parent
        relative_path = ""
        term.proxy_pointer.each_with_index do |proxy_pointer, proxy_pointer_index|
          proxy_term = current_location.retrieve_term(proxy_pointer)
          proxy_relative_path = proxy_term.xpath_relative
          if proxy_pointer_index > 0
            proxy_relative_path = "/"+proxy_relative_path
          end
          relative_path << proxy_relative_path
          current_location = proxy_term
        end
      else  
        relative_path = term.xpath_relative
      
        unless index.nil?
          relative_path = add_node_index_predicate(relative_path, index)
        end
      end
      
      if pointer_index > 0
        relative_path = "/"+relative_path
      end
      xpath << relative_path 
    end
      
    final_term = terminology.retrieve_term(*keys) 
    
    if query_constraints.kind_of?(Hash)
      contains_functions = []
      query_constraints.each_pair do |k,v|
        if k.instance_of?(Symbol)
          constraint_path = final_term.children[k].xpath_relative
        else
          constraint_path = k
        end
        contains_functions << "contains(#{constraint_path}, \"#{v}\")"
      end
      
      xpath = add_predicate(xpath, delimited_list(contains_functions, " and ") )
    end
    
    return xpath
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