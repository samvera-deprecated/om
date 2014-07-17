require "open-uri"

class OM::XML::ParentNodeNotFoundError < RuntimeError; end
module OM::XML::TermValueOperators
  
  # Retrieves all of the nodes from the current document that match +term_pointer+ and returns an array of their values
  def term_values(*term_pointer)
    result = []
    xpath = self.class.terminology.xpath_with_indexes(*term_pointer)
    #if value is on line by itself sometimes does not trim leading and trailing whitespace for a text node so will detect and fix it
    trim_text = !xpath.nil? && !xpath.index("text()").nil?
    find_by_terms(*term_pointer).each {|node| result << (trim_text ? node.text.strip : node.text) }

    if term_pointer.length == 1 && term_pointer.first.kind_of?(String)
      OM.logger.warn "Passing a xpath to term_values means that OM can not properly find the associated term. Pass a term pointer instead." if OM.logger
      result
    else
      term = self.class.terminology.retrieve_term(*OM.pointers_to_flat_array(OM.destringify(term_pointer), false))
      term.deserialize(result)
    end
  end
  
  # alias for term_values
  def property_values(*lookup_args)
    term_values(*lookup_args)
  end
  
  # 
  # @param [Hash] params
  # @example
  #   {[{":person"=>"0"}, "role", "text"]=>{'1'=>"role1", '2' => "role2", '3'=>"role3"}, [{:person=>1}, :family_name]=>"Andronicus", [{"person"=>"1"},:given_name]=>["Titus"],[{:person=>1},:role,:text]=>["otherrole1","otherrole2"] }
  def update_values(params={})
    # remove any terms from params that this datastream doesn't recognize    
    
    params.delete_if do |term_pointer,new_values| 
      if term_pointer.kind_of?(String)
        true
      else
        !self.class.terminology.has_term?(*OM.destringify(term_pointer))
      end
    end
    
    params.inject({}) do |result, (term_pointer,new_values)|
      pointer = OM.destringify(term_pointer)
      hn = OM::XML::Terminology.term_hierarchical_name(*pointer)
      result[hn] = assign_nested_attributes_for_collection_association(pointer, new_values)
      result
    end
  end


  # @see ActiveRecord::NestedAttributes#assign_nested_attributes_for_collection_association
  # @example
  #
  #   assign_nested_attributes_for_collection_association(:people, {
  #     '1' => { name: 'Peter' },
  #     '2' => { name: 'John', role: 'Creator' },
  #     '3' => { name: 'Bess' }
  #   })
  #
  # Will update the name of the Person with ID 1, build a new associated
  # person with the name 'John', and mark the associated Person with ID 2
  # for destruction.
  #
  # Also accepts an Array of attribute hashes:
  #
  #   assign_nested_attributes_for_collection_association(:people, [
  #     { name: 'Peter' },
  #     { name: 'John', role: 'Creator' },
  #     { name: 'Bess' }
  #   ])
  def assign_nested_attributes_for_collection_association(pointer, new_values)
      
      term = self.class.terminology.retrieve_term( *OM.pointers_to_flat_array(pointer,false) )
      xpath = self.class.terminology.xpath_with_indexes(*pointer)
      current_values = term_values(*pointer)

      new_values = term.sanitize_new_values(new_values)
      

      if current_values.length > new_values.length
        starting_index = new_values.length + 1
        starting_index.upto(current_values.size).each do |index|
          term_value_delete select: xpath, child_index: index
        end
      end

      # Populate the response hash appropriately, using hierarchical names for terms as keys rather than the given pointers.
      result = new_values.dup
      
      # Fill out the pointer completely if the final term is a NamedTermProxy
      if term.kind_of? OM::XML::NamedTermProxy
        pointer.pop
        pointer = pointer.concat(term.proxy_pointer)
      end
      
      parent_pointer = pointer.dup
      parent_pointer.pop
      parent_xpath = self.class.terminology.xpath_with_indexes(*parent_pointer)

      template_pointer = OM.pointers_to_flat_array(pointer,false)
      
      # If the value doesn't exist yet, append it.  Otherwise, update the existing value.
      new_values.each_with_index do |z, y|
        if find_by_terms(*pointer)[y.to_i].nil?
          result.delete(y)
          term_values_append(:parent_select=>parent_pointer,:parent_index=>0,:template=>template_pointer,:values=>z)
          new_array_index = find_by_terms(*pointer).length - 1
          result[new_array_index] = z
        else
          term_value_update(xpath, y.to_i, z)
        end
      end

      return result
  end
  
  def term_values_append(opts={})
    parent_select = Array( opts[:parent_select] )
    parent_index = opts[:parent_index]
    template = opts[:template]
    new_values = Array( opts[:values] )  
    
    parent_nodeset = find_by_terms(*parent_select)
    parent_node = node_from_set(parent_nodeset, parent_index)
    
    if parent_node.nil?
      if parent_select.empty?
        parent_node = ng_xml.root
      else
        parent_node = build_ancestors(parent_select, parent_index)
      end
    end

    insert_from_template(parent_node, new_values, template)
    
    return parent_node
    
  end

  # Insert xml containing +new_values+ into +parent_node+.  Generate the xml based on +template+ 
  # @param [Nokogiri::XML::Node] parent_node to insert new xml into
  # @param [Array] new_values to build the xml around
  # @param [Array -- (OM term pointer array) OR String -- (like what you would pass into Nokogiri::XML::Builder.new)] template for building the new xml.  Use the syntax that Nokogiri::XML::Builder uses.
  # @return [Nokogiri::XML::Node] the parent_node with new chldren inserted into it
  def insert_from_template(parent_node, new_values, template)
    ng_xml_will_change!
    # If template is a string, use it as the template, otherwise use it as arguments to xml_builder_template
    unless template.instance_of?(String)
      template_args = Array(template)
      if template_args.last.kind_of?(Hash)
        template_opts = template_args.delete_at(template_args.length - 1)
        template_args << template_opts
      end
      template_args = OM.pointers_to_flat_array(template_args,false)
      template = self.class.terminology.xml_builder_template( *template_args )
    end

    #if there is an xpath element pointing to text() need to change to just 'text' so it references the text method for the parent node
    template.gsub!(/text\(\)/, 'text')
    
    builder = Nokogiri::XML::Builder.with(parent_node) do |xml|
      new_values.each do |builder_new_value|
        builder_new_value = builder_new_value.gsub(/'/, "\\\\'") # escape any apostrophes in the new value
        if matchdata = /xml\.@(\w+)/.match(template)
          parent_node.set_attribute(matchdata[1], builder_new_value)
        else 
          builder_arg = eval('"'+ template + '"') # this inserts builder_new_value into the builder template
          eval(builder_arg)
        end
      end
    end
    return parent_node
  end
  
  # Creates necesary ancestor nodes to support inserting a new term value where the ancestor node(s) don't exist yet.
  # Corrects node indexes in the pointer array to correspond to the ancestors that it creates.
  # Returns a two-value array with the 'parent' node and a corrected pointer array
  # @return [Nokogiri::XML::Node] the 'parent' (the final node in the ancestor tree)
  # @return [Array] corrected pointer array for retrieving this parent
  def build_ancestors(parent_select, parent_index)
    parent_select = Array(parent_select)
    parent_nodeset = find_by_terms(*parent_select)
    starting_point = node_from_set(parent_nodeset, parent_index)
    if starting_point.nil? 
      starting_point = [] 
    end
    to_build = []
    until !starting_point.empty?
      to_build = [parent_select.pop] + to_build
      starting_point = find_by_terms(*parent_select)
      if starting_point.empty? && parent_select.empty? 
        raise OM::XML::TemplateMissingException, "Cannot insert nodes into the document because it is empty.  Try defining self.xml_template on the #{self.class} class."
      end
    end
    to_build.each do |term_pointer|      
      parent_select << term_pointer
      
      # If pointers in parent_select don't match with the indexes of built ancestors, correct the hash
      if find_by_terms(*parent_select+[{}]).length == 0
        if parent_select.last.kind_of?(Hash)
          suspect_pointer = parent_select.pop
          term_key = suspect_pointer.keys.first
          if parent_select.empty?
            corrected_term_index = find_by_terms(term_key).length
          else
            corrected_term_index = find_by_terms(*parent_select+[{}]).length
          end
          parent_select << {term_key => corrected_term_index}
        end
      end
      template_pointer = OM.pointers_to_flat_array(parent_select,false)
      new_values = [""]
      insert_from_template(starting_point.first, new_values, template_pointer)
      starting_point = find_by_terms(*parent_select+[{}])
      # If pointers in parent_select don't match with the indexes of built ancestors, correct the hash
      if starting_point.empty?
        raise ::StandardError, "Oops.  Something went wrong adding #{term_pointer.inspect} to #{parent_select.inspect} while building ancestors.  Expected to find something at #{self.class.terminology.xpath_for(*parent_select)}. The current xml is\n #{self.to_xml}"
      end
    end
    if parent_index > starting_point.length
      parent_index = starting_point.length - 1
    end
    return node_from_set(starting_point, parent_index)
  end
  
  def term_value_update(node_select,node_index,new_value,opts={})
    ng_xml_will_change!
    
    node = find_by_terms_and_value(*node_select)[node_index]
    if delete_on_update?(node, new_value)
      node.remove
    else
      node.content = new_value
    end
  end

  def delete_on_update?(node, new_value)
    new_value.nil? || new_value == :delete
  end
  
  # def term_value_set(term_ref, query_opts, node_index, new_value)
  # end
  
  def term_value_delete(opts={})
    ng_xml_will_change!
    parent_select = Array( opts[:parent_select] )
    parent_index = opts[:parent_index]
    child_index = opts[:child_index]
    xpath_select = opts[:select]
    
    if !xpath_select.nil?
      node = find_by_terms_and_value(xpath_select).first
    else
      # parent_nodeset = find_by_terms_and_value(parent_select, parent_select)
      parent_nodeset = find_by_terms_and_value(*parent_select)
      
      if parent_index.nil?
        node = node_from_set(parent_nodeset, child_index)
      else
        parent = node_from_set(parent_nodeset, parent_index)
        # this next line is a hack around the fact that element_children() sometimes doesn't work.
        node = node_from_set(parent.xpath("*"), child_index)
      end
    end
    
    node.remove
  end
   
  
  # Allows you to provide an array index _or_ a symbol representing the function to call on the nodeset in order to retrieve the node.
  def node_from_set(nodeset, index)
    if index.kind_of?(Integer)
      node = nodeset[index]
    elsif index.kind_of?(Symbol) && nodeset.respond_to?(index) 
      node = nodeset.send(index)
    else
      raise "Could not retrieve node using index #{index}."
    end
    
    return node
  end
  
  private :node_from_set
  
end
