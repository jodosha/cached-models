require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "ActiveRecord::Base" do
  before(:each) do
    @cache = ActiveRecord::Base.associations_cache
    @post  = Factory.create(:post)
    @reflection = ActiveRecord::Associations::HasManyAssociation.new(@post, Post.reflect_on_association(:comments))
    @cache.clear rescue nil
  end

  it "should have a cache" do
    ActiveRecord::Base.associations_cache.should_not be_nil
  end

  it "should generate a cache key for the cached association" do
    @post.send(:association_cache_key, @reflection).should == "#{@post.cache_key}/#{@reflection.name}"
  end

  it "should store in cache" do
    association_cache_key = @post.send(:association_cache_key, @reflection)
    @post.send(:cache_write, @reflection, "value").should be_true
    @cache.read(association_cache_key).should == "value"
  end

  it "should delete from cache" do
    association_cache_key = @post.send(:association_cache_key, @reflection)
    @cache.write(association_cache_key, "value")
    @post.send(:cache_delete, @reflection).should be_true
    @cache.read(association_cache_key).should be_nil
  end
end