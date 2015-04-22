require 'spec_helper'

describe "OM::XML::NamedTermProxy" do
  
  before(:all) do
    
    class NamedProxyTestDocument 
      include OM::XML::Document
      set_terminology do |t|
        t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")
        t.parent {
          t.foo {
            t.bar
          }
          t.my_proxy(:proxy=>[:foo, :bar])
        }
        t.adoptive_parent(:ref=>[:parent], :attributes=>{:type=>"adoptive"})
        t.parentfoobarproxy(:proxy=>[:parent, :foo, :bar])
      end
      def self.xml_template 
        '<mods xmlns="http://www.loc.gov/mods/v3"><parent><foo/></parent></mods>'
      end
    end
    
    @test_terminology = NamedProxyTestDocument.terminology
    @test_proxy = @test_terminology.retrieve_term(:parent, :my_proxy)
    @proxied_term = @test_terminology.retrieve_term(:parent, :foo, :bar)
    @adoptive_parent = @test_terminology.retrieve_term(:adoptive_parent)

  end
    
  it "should proxy all extra methods to the proxied object" do
    [:xpath, :xpath_relative, :xml_builder_template].each do |method|
      expect(@proxied_term).to receive(method)
      @test_proxy.send(method)
    end
  end

  it "should proxy the term specified by the builder" do
    expect(@test_proxy.proxied_term).to eq(@test_terminology.retrieve_term(:parent, :foo, :bar))
    expect(@test_proxy.xpath).to eq "//oxns:parent/oxns:foo/oxns:bar"
  end

  it "should search relative to the parent term when finding the term to proxy" do
    proxy2 = @test_terminology.retrieve_term(:adoptive_parent, :my_proxy)    
    expect(proxy2.proxied_term).to eq @test_terminology.retrieve_term(:adoptive_parent, :foo, :bar)
    expect(proxy2.xpath).to eq '//oxns:parent[@type="adoptive"]/oxns:foo/oxns:bar'
  end

  it "should support NamedTermProxies that point to root terms" do
    expect(@test_terminology.xpath_for(:parentfoobarproxy)).to eq("//oxns:parent/oxns:foo/oxns:bar")
  end

  it "should be usable in update_values" do
    document = NamedProxyTestDocument.from_xml(NamedProxyTestDocument.xml_template)
    document.update_values([:parentfoobarproxy] => "FOObar!")
    expect(document.term_values(:parentfoobarproxy)).to eq ["FOObar!"]
  end
  
end
