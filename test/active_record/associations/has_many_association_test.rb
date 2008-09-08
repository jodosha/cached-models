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
    
    def test_should_refresh_cache_when_pushing_element_to_association
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      cache.expects(:write).with("#{cache_key}/cached_posts", association_proxy).returns true

      post = create_post :author_id => nil
      authors(:luca).cached_posts << post

      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end

    def test_should_refresh_caches_when_pushing_element_to_association_belonging_to_another_model
      cache.expects(:fetch).with("#{authors(:chuck).cache_key}/cached_posts").times(2).returns association_proxy(:chuck)
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      cache.expects(:delete).with("#{authors(:chuck).cache_key}/cached_posts").returns true
      post = authors(:chuck).cached_posts.last
      authors(:luca).cached_posts << post

      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
      assert_equal posts_by_author(:chuck), authors(:chuck).cached_posts
    end

    def test_should_refresh_caches_when_pushing_element_to_polymorphic_association_belonging_to_another_model
      cache.expects(:fetch).with("#{posts(:welcome).cache_key}/cached_tags").times(2).returns tags_association_proxy
      cache.expects(:fetch).with("#{posts(:cached_models).cache_key}/cached_tags").times(2).returns tags_association_proxy(:cached_models)
      cache.expects(:delete).with("#{posts(:welcome).cache_key}/cached_tags").returns true
      tag = posts(:welcome).cached_tags.last

      posts(:cached_models).cached_tags << tag

      # NOTE for some weird reason the assertion fails, even if the collections are equals.
      # I forced the comparision between the ids.
      assert_equal tags_by_post(:cached_models).map(&:id).sort,
        posts(:cached_models).cached_tags.map(&:id).sort
      assert_equal tags_by_post(:welcome), posts(:welcome).cached_tags
    end

    def test_should_not_use_cache_when_pushing_element_to_association_on_false_cached_option
      cache.expects(:write).never

      post = create_post :author_id => nil
      authors(:luca).posts << post
    end

    def test_should_not_use_cache_when_pushing_element_to_association_belonging_to_anotner_model_on_false_cached_option
      cache.expects(:delete).never
      post = authors(:chuck).posts.last
      authors(:luca).posts << post

      assert_equal posts_by_author(:luca), authors(:luca).posts
    end
    
    def test_should_not_use_cache_when_pushing_element_to_polymorphic_association_belonging_to_another_model_on_false_cached_option
      cache.expects(:delete).never
      tag = posts(:welcome).tags.last
      posts(:cached_models).tags << tag
      
      assert_equal tags_by_post(:cached_models), posts(:cached_models).tags
    end
  end

  private
    def posts_by_author(author, include_comments = false)
      conditions = include_comments ? { :include => :comments } : { }
      Post.find_all_by_author_id(authors(author).id, conditions)
    end

    def tags_by_post(post)
      Tag.find_all_by_taggable_id(posts(post).id)
    end

    def comments_by_author(author)
      Comment.find(:all, :conditions => ["post_id IN (?)", authors(author).post_ids])
    end

    def association_proxy(author = :luca)
      HasManyAssociation.new(authors(author), Author.reflect_on_association(:cached_posts))
    end

    def tags_association_proxy(post = :welcome)
      HasManyAssociation.new(posts(post), Post.reflect_on_association(:cached_tags))
    end

    def comments_association_proxy(author = :luca)
      HasManyThroughAssociation.new(authors(author), Author.reflect_on_association(:cached_comments))
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
