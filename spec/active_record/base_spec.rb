require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "ActiveRecord::Base" do
  it "should have a cache" do
    ActiveRecord::Base.associations_cache.should_not be_nil
  end
end