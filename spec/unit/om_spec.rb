require 'spec_helper'

describe "OM" do
  
  describe "#{}destringify" do
    it "should recursively change any strings beginning with : to symbols and any number strings to integers" do
      expect(OM.destringify( [{":person"=>"0"}, ":last_name"] )).to eq([{:person=>0}, :last_name])
      expect(OM.destringify( [{"person"=>"3"}, "last_name"] )).to eq([{:person=>3}, :last_name])
    end
  end
  
end
