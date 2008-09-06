require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Harvester, "index action" do
  it "should find all the apps" do
    App.should_receive(:find).with(:all).once.and_return([])
    dispatch_to(Harvester, :index)    
  end
end

describe Harvester, "harvest action" do
  
end