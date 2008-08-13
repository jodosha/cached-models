require File.dirname(__FILE__) + '/../../test_helper'
require 'active_record/associations/has_many_association'

class HasManyAssociationTest < Test::Unit::TestCase
  include ActiveRecord::Associations
  
  uses_mocha 'HasManyAssociationTest' do
    def test_should_not_use_cache_on_false_cached_option
      cache.expects(:fetch).never
      authors(:luca).posts
      authors(:luca).posts(true) # force reload
    end
    
    def test_should_cache_associated_objects
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns(posts_by_author(:luca))

      posts = authors(:luca).cached_posts
      assert_equal posts, authors(:luca).cached_posts
    end
    
    def test_should_reload_association_and_refresh_the_cache_on_force_reload
      cache.expects(:delete).with("#{cache_key}/cached_posts").returns true
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns(posts_by_author(:luca))

      reloaded_posts = authors(:luca).cached_posts(true)
      assert_equal reloaded_posts, authors(:luca).cached_posts
    end
    
    def test_should_cache_associated_ids
      cache.expects(:fetch).with("#{cache_key}/cached_post_ids").times(2).returns(posts_by_author(:luca).map(&:id))
      ids = authors(:luca).cached_post_ids
      assert_equal ids, authors(:luca).cached_post_ids
    end
    
    def test_should_not_cache_associated_ids_on_false_cached_option
      cache.expects(:fetch).never
      authors(:luca).post_ids
    end
    
    def test_should_cache_all_eager_loaded_objects
      cache.expects(:fetch).with("#{cache_key}/cached_posts_with_comments").times(2).returns(posts_by_author(:luca, true))
      posts = authors(:luca).cached_posts_with_comments
      assert_equal posts, authors(:luca).cached_posts_with_comments
    end
    
    def test_should_not_cache_eager_loaded_objects_on_false_cached_option
      cache.expects(:fetch).never
      authors(:luca).posts_with_comments
    end
    
    def test_should_cache_polymorphic_associations
      cache.expects(:fetch).with("#{posts(:cached_models).cache_key}/cached_tags").times(2).returns(tags_by_post(:cached_models))
      tags = posts(:cached_models).cached_tags
      assert_equal tags, posts(:cached_models).cached_tags
    end
    
    def test_should_not_cache_polymorphic_associations_on_false_cached_option
      cache.expects(:fetch).never
      posts(:cached_models).tags
    end
    
    def test_should_cache_habtm_associations
      cache.expects(:fetch).with("#{cache_key}/cached_comments").times(2).returns(comments_by_author(:luca))
      comments = authors(:luca).cached_comments
      assert_equal comments, authors(:luca).cached_comments
    end
    
    def test_should_not_cache_habtm_associations_on_false_cached_option
      cache.expects(:fetch).never
      authors(:luca).comments
    end
    
    def test_should_refresh_cache_when_pushing_new_associated_elements
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      # FIXME the expectation is unsatisfied because the fixtures hasn't explicit timestamps,
      # the push operation causes an update of the user updated_at column, this causes a change
      # of the cache_key value.
      # cache.expects(:write).with("#{cache_key}/cached_posts").returns true

      post = create_post :author_id => nil
      authors(:luca).cached_posts << post

      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end
  end
  
  private
    def posts_by_author(author, include_comments = false)
      conditions = include_comments ? { :include => :comments } : { }
      Post.find_all_by_author_id(authors(author).id, conditions)
    end
    
    def tags_by_post(post)
      @tags_by_post ||= Tag.find_all_by_taggable_id(posts(post).id)
    end
    
    def comments_by_author(author)
      @comments_by_author ||= Comment.find(:all, :conditions => ["post_id IN (?)", authors(author).post_ids])
    end
    
    def association_proxy
      HasManyAssociation.new(authors(:luca), Author.reflect_on_association(:cached_posts))
    end
    
    def create_post(options = {})
      Post.new({ :author_id => 1,
        :title => 'CachedModels',
        :text => 'Introduction to CachedModels plugin',
        :published_at => 1.week.ago }.merge(options))
    end
    
    def cache_key
      @cache_key ||= authors(:luca).cache_key
    end
end
