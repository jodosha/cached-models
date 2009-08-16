class Post < ActiveRecord::Base
  has_many :comments, :cached => true
end