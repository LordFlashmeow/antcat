require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Publisher do

  describe "importing" do
    it "should create and return the publisher" do
      publisher = Publisher.import(:name => 'Wiley', :place => 'Chicago')
      publisher.name.should == 'Wiley'
      publisher.place.should == 'Chicago'
    end

    it "should reuse an existing publisher" do
      2.times {Publisher.import(:name => 'Wiley', :place => 'Chicago')}
      Publisher.count.should == 1
    end
  end

  describe "searching" do
  end

  describe "importing a string" do
    it "should handle a blank string" do
      Publisher.should_not_receive :import
      Publisher.import_string ''
    end
    it "should parse it correctly" do
      publisher = mock_model Publisher
      Publisher.should_receive(:import).with(:name => 'Houghton Mifflin', :place => 'New York').and_return publisher
      Publisher.import_string('New York: Houghton Mifflin').should == publisher
    end
  end

end
