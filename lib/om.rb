require 'rubygems'

require 'nokogiri'
require "facets"

module OM
  # @params String, Array, or Hash
  # Recursively changes any strings beginning with : to symbols and any number strings to integers
  # Converts [{":person"=>"0"}, ":last_name"] to [{:person=>0}, :last_name]
  def self.destringify(params)
    case params
    when String       
      if params == "0" || params.to_i != 0
        result = params.to_i
      elsif params[0,1] == ":"
        result = params.sub(":","").to_sym
      else
        result = params.to_sym
      end
      return result
    when Hash 
      result = {}
      params.each_pair do |k,v|
        result[ destringify(k) ] = destringify(v)
      end
      return result
    when Array 
      result = []
      params.each do |x|
        result << destringify(x)
      end
      return result
    else
      return params
    end
  end
  
  # @pointers pointers array that you would pass into other Accessor methods
  # @include_indices (default: true) if set to false, parent indices will be excluded from the array
  # Converts an array of accessor pointers into a flat array.
  # ie. [{:conference=>0}, {:role=>1}, :text] becomes [:conference, 0, :role, 1, :text]
  #   if include_indices is set to false,
  #     [{:conference=>0}, {:role=>1}, :text] becomes [:conference, :role, :text]
  def self.pointers_to_flat_array(pointers, include_indices=true)
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

module OM::XML; end

require "om/tree_node"
require "om/xml"
require "om/samples"


