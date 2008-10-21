class Author < ActiveRecord::Base
  belongs_to :blog, :cached => true
  has_many :posts
  has_many :cached_posts, :cached => true, :class_name => 'Post'
  has_many :uniq_cached_posts, :cached => true, :class_name => 'Post', :uniq => true
  has_many :cached_dependent_posts, :cached => true, :class_name => 'Post', :dependent => :destroy
  has_many :posts_with_comments, :class_name => 'Post', :include => :comments
  has_many :cached_posts_with_comments, :class_name => 'Post', :include => :comments, :cached => true
  has_many :comments, :through => :posts
  has_many :cached_comments, :through => :posts, :source => :comments, :cached => true
  has_one :address
end
