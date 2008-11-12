class Category < ActiveRecord::Base
  has_and_belongs_to_many :posts
  has_and_belongs_to_many :cached_posts, :class_name => 'Post', :cached => true
  has_and_belongs_to_many :posts_with_comments, :class_name => 'Post', :include => :comments
  has_and_belongs_to_many :cached_posts_with_comments, :class_name => 'Post', :include => :comments, :cached => true
  has_and_belongs_to_many :uniq_cached_posts, :cached => true, :class_name => 'Post', :uniq => true
end
