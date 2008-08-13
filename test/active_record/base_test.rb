require File.dirname(__FILE__) + '/../test_helper'

class BaseTest < Test::Unit::TestCase
  def test_should_have_cache
    assert_equal RAILS_CACHE, ActiveRecord::Base.rails_cache
  end
  
  def test_should_wrap_rails_cache
    assert_equal RAILS_CACHE, Post.new.send(:rails_cache)
  end
end
