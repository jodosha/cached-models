require File.dirname(__FILE__) + '/../../test_helper'

class HasAndBelongsToManyAssociationTest < Test::Unit::TestCase
  include ActiveRecord::Associations
  
  def test_should_not_raise_exception
    assert_nothing_raised ArgumentError do
      posts(:welcome).categories
      categories(:announcements).posts
    end
  end
end
