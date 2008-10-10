require File.dirname(__FILE__) + '/../test_helper'

class BaseTest < Test::Unit::TestCase
  fixtures :authors

  def test_should_have_cache
    assert_equal RAILS_CACHE, ActiveRecord::Base.rails_cache if defined? Rails
    assert_kind_of ActiveSupport::Cache::Store, ActiveRecord::Base.rails_cache
  end
  
  def test_should_wrap_rails_cache
    assert_equal RAILS_CACHE, Post.new.send(:rails_cache) if defined? Rails
    assert_kind_of ActiveSupport::Cache::Store, Post.new.send(:rails_cache)
  end
  
  def test_reflection_cache_key
    author = authors(:luca)
    actual = author.send(:reflection_cache_key, Author.reflections[:cached_posts])
    assert_equal "#{author.cache_key}/cached_posts", actual
  end
  
  def test_cached_association
    author = authors(:luca)
    assert_equal({}, author.send(:cached_associations))
    
    author.cached_posts # force cache loading
    assert_equal({:cached_posts => true}, author.send(:cached_associations))
    
    author.send(:cache_delete, Author.reflections[:cached_posts])
    assert_equal({:cached_posts => false}, author.send(:cached_associations))
  end
end
