# coding: UTF-8
require 'spec_helper'

describe Taxt do

  describe "Encodings" do
    it "should encode an unparseable string" do
      Taxt.unparseable('foo').should == '{? foo}'
    end
    it "should encode an unparseable string" do
      reference = Factory :book_reference
      Taxt.reference(reference).should == "{ref #{reference.id}}"
    end
  end

  describe "Interpolation" do

    it "should leave alone a string without fields" do
      Taxt.interpolate('foo').should == 'foo'
    end
    it "should format a ref" do
      reference = Factory :article_reference
      key_stub = stub
      key_stub.should_receive(:to_link).and_return('foo')
      Reference.should_receive(:find).with(reference.id.to_s).and_return reference
      reference.should_receive(:key).and_return key_stub
      Taxt.interpolate("{ref #{reference.id}}").should == 'foo'
    end
    it "should not freak if the ref is malformed" do
      Taxt.interpolate("{ref sdf}").should == '{ref sdf}'
    end
    it "should not freak if the ref points to a reference that doesn't exist" do
      Taxt.interpolate("{ref 12345}").should == '{ref 12345}'
    end
    it "should handle a MissingReference" do
      reference = Factory :missing_reference, :citation => 'Latreille, 1809'
      Taxt.interpolate("{ref #{reference.id}}").should == 'Latreille, 1809'
    end

  end

end
