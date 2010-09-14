require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "om"

describe "OM::XML::NamedTermProxy" do
  
  before(:all) do
    
    @test_terminology_builder = OM::XML::Terminology::Builder.new do |t|
      t.parent {
        t.foo {
          t.bar
        }
        t.my_proxy(:proxy_relative=>[:foo, :bar])
      }
      t.adoptive_parent(:ref=>[:parent], :attributes=>{:type=>"adoptive"})
    end
    
    @test_terminology = @test_terminology_builder.build
    @test_proxy = @test_terminology.retrieve_term(:parent, :my_proxy)
    @proxied_term = @test_terminology.retrieve_term(:parent, :foo, :bar)
    @adoptive_parent = @test_terminology.retrieve_term(:adoptive_parent)
  end
    
  it "should proxy all extra methods to the proxied object" do
    [:xpath, :xpath_relative, :xml_builder_template].each do |method|
      @proxied_term.expects(method)
      @test_proxy.send(method)
    end
  end
  it "should proxy the term specified by the builder" do
    @test_proxy.proxied_term.should == @test_terminology.retrieve_term(:parent, :foo, :bar)
    @test_proxy.xpath.should == "//oxns:parent/oxns:foo/oxns:bar"
  end
  it "should search relative to the parent term when finding the term to proxy" do
    proxy2 = @test_terminology.retrieve_term(:adoptive_parent, :my_proxy)    
    proxy2.proxied_term.should == @test_terminology.retrieve_term(:adoptive_parent, :foo, :bar)
    proxy2.xpath.should == '//oxns:parent[@type="adoptive"]/oxns:foo/oxns:bar'
  end
end