ActiveRecord::Schema.define do
  create_table :addresses, :force => true do |t|
    t.integer :author_id
    t.string :street
    t.string :zip
    t.string :city
    t.string :state
    t.string :country

    t.timestamps
  end

  create_table :authors, :force => true do |t|
    t.integer :blog_id
    t.string  :first_name
    t.string  :last_name
    t.integer :age

    t.timestamps
  end
  
  create_table :blogs, :force => true do |t|
    t.string :title

    t.timestamps
  end
  
  create_table :posts, :force => true do |t|
    t.integer :author_id
    t.integer :blog_id
    t.string :title
    t.text :text
    t.datetime :published_at
    t.integer :rating, :default => 0

    t.timestamps
  end
  
  create_table :categories, :force => true do |t|
    t.string :name

    t.timestamps
  end

  create_table :categories_posts, :force => true, :id => false do |t|
    t.integer :category_id
    t.integer :post_id
  end

  create_table :comments, :force => true do |t|
    t.integer :post_id
    t.string :email
    t.text :text

    t.timestamps
  end

  create_table :tags, :force => true do |t|
    t.integer :taggable_id
    t.string :taggable_type
    t.string :name

    t.timestamps
  end
end
