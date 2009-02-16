require File.dirname(__FILE__) + '/../../test_helper'

class HasOneAssociationTest < ActiveSupport::TestCase
  include ActiveRecord::Associations

  def test_should_not_raise_exception_when_use_has_one
    assert_nothing_raised ArgumentError do
      authors(:luca).address
      addresses(:luca).author
    end
  end
end
