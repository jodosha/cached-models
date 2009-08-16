ActiveRecord::Schema.define do
  create_table :posts, :force => true do |t|
    t.integer :author_id
    t.integer :blog_id
    t.string :title
    t.text :text
    t.datetime :published_at
    t.integer :rating, :default => 0

    t.timestamps
  end

  create_table :comments, :force => true do |t|
    t.integer :post_id
    t.string :email
    t.text :text

    t.timestamps
  end
end
