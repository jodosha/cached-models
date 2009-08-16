require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "ActiveRecord::Associations" do
  before(:each) do
    @cache = ActiveRecord::Base.associations_cache
    @post  = Factory.create(:post)
    @cache.clear rescue nil
  end

  describe "has_many" do
    it "should store results in cache" do
      @post.comments
      @cache.read("#{@post.cache_key}/comments").should_not be_nil
    end

    it "should expire cache on association update" do
      @post.comments # pre-load cache
      @post.comments.create Factory.attributes_for(:comment)
      @post.comments.should == @cache.read("#{@post.cache_key}/comments")
    end
  end
end