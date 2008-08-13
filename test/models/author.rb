class Author < ActiveRecord::Base
  has_many :posts
  has_many :cached_posts, :cached => true, :class_name => 'Post'
  has_many :posts_with_comments, :class_name => 'Post', :include => :comments
  has_many :cached_posts_with_comments, :class_name => 'Post', :include => :comments, :cached => true
  has_many :comments, :through => :posts
  has_many :cached_comments, :through => :posts, :source => :comments, :cached => true
end
