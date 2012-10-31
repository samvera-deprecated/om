require 'rubygems'
require 'active_support/concern'
require 'active_model/dirty'
require 'deprecation'
require 'nokogiri'

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
  
  # Convert a Term pointer into a flat array without Hashes.
  # If include_indices is set to false, node indices will be removed.
  #
  # @param [Array] pointers array that you would pass into other Accessor methods
  # @param [Boolean] include_indices (default: true) if set to false, parent indices will be excluded from the array
  # @example Turn a pointer into a flat array with node indices preserved
  #   OM.pointers_to_flat_array( [{:conference=>0}, {:role=>1}, :text] ) 
  #   => [:conference, 0, :role, 1, :text]
  # @example Remove node indices by setting include_indices to false
  #   OM.pointers_to_flat_array( [{:conference=>0}, {:role=>1}, :text], false ) 
  #   => [:conference, :role, :text]
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

  def self.version
    Om::VERSION
  end
end

module OM::XML; end

require "om/tree_node"
require "om/xml"
require "om/samples"
require "om/version"

