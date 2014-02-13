require_relative './spec_helper.rb'


describe Informer do
  before :all do
    create_test_repo
    @informer = Informer.new('/Users/kleetus/pivotal.yml')
    @informer.testdb = 'test.db'
    @database = Database.new('test.db')
  end

  it "should deal with no previous record in db" do
    res = @informer.send_tag("v99.99.99")
    res.should == [{60630090=>"v99.99.99"}] 
  end

  it "should send_tag successfully" do
    preload_sha
    res = @informer.send_tag("v99.99.99")
    res.should == [{60630090=>"v99.99.99"}, {61074466=>"v99.99.99"}, {56889564=>"v99.99.99"}] 
  end


  after :all do
    `rm -fr test.d*`
    `rm -fr .git test.txt`  
  end
 
  def create_test_repo
    `touch test.txt`
    `git init`
    ['65204950', '64864658', '56889564', '61074466', '60630090'].each do |c|
      f=File.open('test.txt', 'w')
      f.write(c)
      f.close
      `git add .`
      `git commit -m"[CK][#{c}]commit #{c}"`
    end
  end 

  def preload_sha
    starting_sha = `git show HEAD~3`.split[1]
    project_name = File.expand_path('..').split('/').last
    @database.post_last_record({commit: starting_sha, project_name: project_name}) 
  end
  
end
