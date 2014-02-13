require_relative './spec_helper.rb'

describe Database do
  before :each do
    @database = Database.new('/tmp', 'test.db')
  end

  it "should insert a record into the table and read it back" do
    @database.post_last_record({commit: 'abcdefgh', project_name: 'test project'})
    @database.read_last_record('test project').should == 'abcdefgh' 
  end
  
  it "should insert more than one record and read back only the latest one" do
    @database.post_last_record({commit: 'abcdefgh', project_name: 'test project'})
    @database.post_last_record({commit: 'hgfedcba', project_name: 'test project'})
    @database.read_last_record('test project').should == 'hgfedcba' 
  end 

  after :each do
    system "rm -fr /tmp/test.d*"
  end
end
