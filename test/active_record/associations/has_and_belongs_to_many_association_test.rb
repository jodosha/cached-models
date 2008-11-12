require File.dirname(__FILE__) + '/../../test_helper'

class HasAndBelongsToManyAssociationTest < Test::Unit::TestCase
  include ActiveRecord::Associations
  
  def setup
    cache.clear rescue nil
  end

  uses_mocha 'HasAndBelongsToManyAssociationTest' do
    def test_should_always_use_cache_for_all_instances_which_reference_the_same_record
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      expected = category.cached_posts
      actual = Category.last.cached_posts
      assert_equal expected, actual
    end

    def test_should_expire_cache_on_update
      cache.expects(:read).with("#{cache_key}/cached_posts").times(2).returns association_proxy

      category.cached_posts # force cache loading
      category.update_attributes :name => category.name.upcase

      assert_equal posts_by_category(:rails), category.cached_posts
    end

    def test_should_use_cache_when_find_with_scope
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      post = category.cached_posts.find(posts(:cached_models).id)
      assert_equal posts(:cached_models), post
    end

    def test_should_use_cache_when_find_with_scope_using_multiple_ids
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      posts = posts_by_category(:rails)
      assert_equal posts, category.cached_posts.find(posts.map(&:id))
    end

    def test_should_use_cache_when_fetch_first_from_collection
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal [ posts_by_category(:rails).first ], category.cached_posts.first(1)
    end

    def test_should_use_cache_when_fetch_last_from_collection
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal [ posts_by_category(:rails).last ], category.cached_posts.last(1)
    end

    def test_should_unload_cache_when_reset_collection
      cache.expects(:read).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      assert_false category.cached_posts.reset
      assert_equal posts_by_category(:rails), category.cached_posts
    end

    def test_should_not_use_cache_on_collection_sum
      # calculations aren't supported for now
      # TODO verify
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal posts_by_category(:rails).map(&:rating).sum, category.cached_posts.sum(:rating)
    end

    def test_should_not_use_cache_on_false_cached_option
      cache.expects(:read).never
      category.posts
      category.posts(true) # force reload
    end

    def test_should_cache_associated_objects
      cache.expects(:read).with("#{cache_key}/cached_posts").times(2).returns(posts_by_category(:rails))
      posts = category.cached_posts
      assert_equal posts, category.cached_posts
    end

    def test_should_safely_use_pagination
      # pagination for now bypass cache and using database.
      # the expectation is due to #cached_posts invocation.
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      posts = category.cached_posts.paginate(:all, :page => 1, :per_page => 1)
      assert_equal [ posts_by_category(:announcements).first ], posts
    end

    def test_should_reload_association_and_refresh_the_cache_on_force_reload
      cache.expects(:read).with("#{cache_key}/cached_posts").times(2).returns(posts_by_category(:rails))
      cache.expects(:write).times(3).returns true
      reloaded_posts = category.cached_posts(true)
      assert_equal reloaded_posts, category.cached_posts
    end

    def test_should_cache_associated_ids
      posts = posts_by_category(:rails)
      ids = posts.map(&:id)
      cache.expects(:read).with("#{cache_key}/cached_posts").returns posts
      cache.expects(:fetch).with("#{cache_key}/cached_post_ids").returns ids
      assert_equal ids, category.cached_post_ids
    end

    def test_should_not_cache_associated_ids_on_false_cached_option
      cache.expects(:fetch).never
      category.post_ids
    end

    def test_should_cache_all_eager_loaded_objects
      cache.expects(:read).with("#{cache_key}/cached_posts_with_comments").returns(posts_by_category(:rails, true))
      posts = category.cached_posts_with_comments
      assert_equal posts, category.cached_posts_with_comments
    end

    def test_should_not_cache_eager_loaded_objects_on_false_cached_option
      cache.expects(:read).never
      category.posts_with_comments
    end
    
    def test_should_refresh_cache_when_associated_elements_change
      cache.expects(:read).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      post = category.cached_posts.last # force cache loading and fetch a post
      post.update_attributes :title => 'Cached Models!'
      assert_equal posts_by_category(:rails), category.cached_posts
    end

    def test_should_refresh_cache_when_pushing_element_to_association
      cache.expects(:read).with("#{cache_key}/cached_posts").times(3).returns association_proxy
      cache.expects(:write).with("#{cache_key}/cached_posts", association_proxy).returns true
      category.cached_posts # force cache loading
      category.cached_posts << create_post
      assert_equal posts_by_category(:rails), category.cached_posts
    end

    def test_should_not_use_cache_when_pushing_element_to_association_on_false_cached_option
      cache.expects(:write).never
      category.posts # force association loading
      category.posts << create_post
    end

    def test_should_not_use_cache_when_pushing_element_to_association_belonging_to_anotner_model_on_false_cached_option
      cache.expects(:delete).with("#{blogs(:weblog).cache_key}/posts").never
      # TODO verify
      cache.expects(:delete).with("#{categories(:rails).cache_key}/cached_posts").returns true
      post = categories(:announcements).posts.first
      category.cached_posts << post
      assert_equal posts_by_category(:rails), category.cached_posts.reverse
    end

    def test_should_update_cache_when_directly_assigning_a_new_collection
      posts = [ posts_by_category(:rails).first ]
      cache.expects(:read).with("#{cache_key}/cached_posts").times(2).returns association_proxy
      category.cached_posts = posts
      assert_equal posts_by_category(:rails), category.cached_posts
    end

    def test_should_use_cache_for_collection_size
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal posts_by_category(:rails).size, category.cached_posts.size
    end

    def test_should_use_cache_and_return_uniq_records_for_collection_size_on_uniq_option
      cache.expects(:read).with("#{cache_key}/uniq_cached_posts").never # wuh?!
      assert_equal posts_by_category(:rails).size, category.uniq_cached_posts.size
    end

    def test_should_use_cache_for_collection_length
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal posts_by_category(:rails).length, category.cached_posts.length
    end

    def test_should_use_cache_for_collection_empty
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal posts_by_category(:rails).empty?, category.cached_posts.empty?
    end

    def test_should_use_cache_for_collection_any
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      assert_equal posts_by_category(:rails).any?, category.cached_posts.any?
    end

    def test_should_use_cache_for_collection_include
      cache.expects(:read).with("#{cache_key}/cached_posts").returns association_proxy
      post = posts_by_category(:rails).first
      assert category.cached_posts.include?(post)
    end
  end

  def test_should_refresh_caches_when_pushing_element_to_association_belonging_to_another_model
    # TODO in this case we should only refresh cache of the new owner
    #
    # example:
    #   post = category1.cached_posts.last
    #   category2.cached_posts << post
    #
    # In this case should expire category2 cache only.
    post = categories(:announcements).cached_posts.first
    category.cached_posts << post
    assert_equal posts_by_category(:rails), category.cached_posts.reverse
    assert_equal posts_by_category(:announcements), categories(:announcements).cached_posts
  end

  def test_should_update_cache_when_pushing_element_with_build
    post = category.cached_posts.build post_options
    post.save
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_update_cache_when_pushing_element_with_create
    category.cached_posts.create post_options(:title => "CM Overview")
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_update_cache_when_pushing_element_with_create_bang_method
    category.cached_posts.create! post_options(:title => "CM Overview!!")
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_expire_cache_when_delete_all_elements_from_collection
    category.cached_posts.delete_all
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_expire_cache_when_destroy_all_elements_from_collection
    category.cached_posts.destroy_all
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_update_cache_when_clearing_collection
    category.cached_posts.clear
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_update_cache_when_deleting_element_from_collection
    category.cached_posts.delete(posts_by_category(:rails).first)
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_update_cache_when_replace_collection
    post = create_post; post.save
    posts = [ posts_by_category(:rails).first, post ]
    category.cached_posts.replace(posts)
    assert_equal posts_by_category(:rails), category.cached_posts
  end

  def test_should_not_expire_cache_on_update_on_missing_updated_at
    category.cached_posts # force cache loading
    category.update_attributes :name => category.name.upcase

    assert_equal posts_by_category(:rails), category.cached_posts
  end

  private
    def association_proxy(category = :rails)
      HasAndBelongsToManyAssociation.new(categories(category), Category.reflect_on_association(:cached_posts))
    end

    def posts_by_category(category, load_comments = false)
      conditions = load_comments ? { :include => :comments } : { }
      Post.find( :all, { :joins => 'LEFT JOIN categories_posts ON posts.id = categories_posts.post_id', 
        :conditions => [ 'category_id = ?', categories(category).id ] }.merge(conditions) )
    end

    def category
      @category ||= categories(:rails)
    end

    def cache_key
      @cache_key ||= category.cache_key
    end
end
