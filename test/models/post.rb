class Post < ActiveRecord::Base
  belongs_to :author, :cached => true
  belongs_to :blog
  has_many :comments
  has_many :tags, :as => :taggable
  has_many :cached_tags, :as => :taggable, :class_name => 'Tag', :cached => true
end
