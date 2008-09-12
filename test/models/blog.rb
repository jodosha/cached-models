class Blog < ActiveRecord::Base
  has_many :authors, :cached => true
  has_many :posts
end
