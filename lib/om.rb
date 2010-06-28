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
end

module OM::XML; end

require "om/xml"


