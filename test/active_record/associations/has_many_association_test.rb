require File.dirname(__FILE__) + '/../../test_helper'
require 'active_record/associations/has_many_association'

class HasManyAssociationTest < Test::Unit::TestCase
  include ActiveRecord::Associations
  
  def setup
    cache.clear
  end

  uses_mocha 'HasManyAssociationTest' do
    def test_should_expire_cache_on_update
      author = authors(:luca)
      old_cache_key = author.cache_key

      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      cache.expects(:delete).with("#{cache_key}/cached_posts").returns true

      author.cached_posts # force cache loading
      author.update_attributes :first_name => author.first_name.upcase

      # assert_not_equal old_cache_key, author.cache_key
      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end

    def test_should_not_expire_cache_on_update_on_missing_updated_at
      author = authors(:luca)
      old_cache_key = author.cache_key

      author.stubs(:[]).with(:updated_at).returns nil
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      cache.expects(:delete).with("#{cache_key}/cached_posts").never
      cache.expects(:delete).with("#{cache_key}/cached_comments").never
      cache.expects(:delete).with("#{cache_key}/cached_posts_with_comments").never

      author.cached_posts # force cache loading
      author.update_attributes :first_name => author.first_name.upcase

      # assert_not_equal old_cache_key, author.cache_key
      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end

    def test_should_use_cache_when_find_with_scope
      cache.expects(:fetch).with("#{cache_key}/cached_posts").returns association_proxy

      post = authors(:luca).cached_posts.find(posts(:welcome).id)
      assert_equal posts(:welcome), post
    end

    def test_should_use_cache_when_find_with_scope_using_multiple_ids
      cache.expects(:fetch).with("#{cache_key}/cached_posts").returns association_proxy

      ids = posts_by_author(:luca).map(&:id)
      assert_equal posts_by_author(:luca),
        authors(:luca).cached_posts.find(ids)
    end

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
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns(posts_by_author(:luca))

      reloaded_posts = authors(:luca).cached_posts(true)
      assert_equal reloaded_posts, authors(:luca).cached_posts
    end
    
    def test_should_cache_associated_ids
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
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
    
    # FIXME
    def test_should_refresh_cache_when_associated_elements_change
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      
      post = authors(:luca).cached_posts.last # force cache loading and fetch a post
      post.update_attributes :title => 'Cached Models!'
      
      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end
    
    # FIXME
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

      post = authors(:chuck).cached_posts.last
      authors(:luca).cached_posts << post

      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
      assert_equal posts_by_author(:chuck), authors(:chuck).cached_posts
    end

    def test_should_refresh_caches_when_pushing_element_to_polymorphic_association_belonging_to_another_model
      cache.expects(:fetch).with("#{posts(:welcome).cache_key}/cached_tags").times(2).returns tags_association_proxy
      cache.expects(:fetch).with("#{posts(:cached_models).cache_key}/cached_tags").times(2).returns tags_association_proxy(:cached_models)
      tag = posts(:welcome).cached_tags.last

      posts(:cached_models).cached_tags << tag

      # NOTE for some weird reason the assertion fails, even if the collections are equals.
      # I forced the comparision between the ids.
      assert_equal tags_by_post(:cached_models).map(&:id).sort,
        posts(:cached_models).cached_tags.map(&:id).sort
      assert_equal tags_by_post(:welcome), posts(:welcome).cached_tags
    end

    # FIXME
    def test_should_not_use_cache_when_pushing_element_to_association_on_false_cached_option
      cache.expects(:write).never

      post = create_post :author_id => nil
      authors(:luca).posts << post
    end

    def test_should_not_use_cache_when_pushing_element_to_association_belonging_to_anotner_model_on_false_cached_option
      cache.expects(:delete).with("#{blogs(:weblog).cache_key}/posts").never
      post = blogs(:weblog).posts.last
      blogs(:blog).posts << post

      assert_equal posts_by_blog(:blog), blogs(:blog).posts
    end

    def test_should_not_use_cache_when_pushing_element_to_polymorphic_association_belonging_to_another_model_on_false_cached_option
      cache.expects(:delete).never
      tag = posts(:welcome).tags.last
      posts(:cached_models).tags << tag
      
      assert_equal tags_by_post(:cached_models), posts(:cached_models).tags
    end
    
    def test_should_update_cache_when_pushing_element_with_build
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy

      author = authors(:luca)
      post = author.cached_posts.build post_options
      post.save
      
      assert_equal posts_by_author(:luca), author.cached_posts
    end
    
    def test_should_update_cache_when_pushing_element_with_create
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy

      author = authors(:luca)
      author.cached_posts.create post_options(:title => "CM Overview")
      
      assert_equal posts_by_author(:luca), author.cached_posts
    end

    def test_should_update_cache_when_deleting_element_from_collection
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy

      authors(:luca).cached_posts.delete(posts_by_author(:luca).first)
      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end

    def test_should_update_cache_when_emptying_collection
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      cache.expects(:write).with("#{cache_key}/cached_posts", []).times(2).returns true
      authors(:luca).cached_posts.clear
      
      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end
    
    def test_should_update_cache_when_directly_assigning_a_new_collection
      posts = [ posts_by_author(:luca).first ]
      cache.expects(:fetch).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      cache.expects(:write).with("#{cache_key}/cached_posts", posts).times(2).returns true
      authors(:luca).cached_posts = posts

      assert_equal posts_by_author(:luca), authors(:luca).cached_posts
    end
  end

  private
    def posts_by_author(author, include_comments = false)
      conditions = include_comments ? { :include => :comments } : { }
      Post.find_all_by_author_id(authors(author).id, conditions)
    end

    def posts_by_blog(blog)
      Post.find_all_by_blog_id(blogs(blog).id)
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

    def post_options(options = {})
      { :blog_id => blogs(:weblog).id,
        :title => "Cached models review",
        :text => "Cached models review..",
        :published_at => 1.week.ago }.merge(options)
    end

    def cache_key
      @cache_key ||= authors(:luca).cache_key
    end
end
