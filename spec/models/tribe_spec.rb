require 'spec_helper'

describe Tribe do

  it "should have a subfamily" do
    subfamily = Factory :subfamily, :name => 'Myrmicinae'
    Factory :tribe, :name => 'Attini', :subfamily => subfamily
    Tribe.find_by_name('Attini').subfamily.should == subfamily
  end

  it "should have genera, which are its children" do
    attini = Factory :tribe, :name => 'Attini'
    Factory :genus, :name => 'Acromyrmex', :tribe => attini
    Factory :genus, :name => 'Atta', :tribe => attini
    attini.genera.map(&:name).should =~ ['Atta', 'Acromyrmex']
    attini.children.should == attini.genera
  end

end
