class Comment < ActiveRecord::Base
  belongs_to :post, :cached => true
end