Gem::Specification.new do |s|
  s.name               = "cached-models"
  s.version            = "0.0.3"
  s.date               = "2008-10-22"
  s.summary            = "Transparent caching policy for your models"
  s.author             = "Luca Guidi"
  s.email              = "guidi.luca@gmail.com"
  s.homepage           = "http://lucaguidi.com/pages/cached_models"
  s.description        = "CachedModels provides to your ActiveRecord models a transparent approach to use ActiveSupport caching mechanism."
  s.has_rdoc           = true
  s.rubyforge_project  = %q{cached-models}
  s.files              = ["CHANGELOG", "MIT-LICENSE", "README", "Rakefile", "about.yml", "cached-models.gemspec", "init.rb", "install.rb", "lib/activerecord/lib/active_record.rb", "lib/activerecord/lib/active_record/associations.rb", "lib/activerecord/lib/active_record/associations/association_collection.rb", "lib/activerecord/lib/active_record/associations/association_proxy.rb", "lib/activerecord/lib/active_record/associations/has_many_association.rb", "lib/activerecord/lib/active_record/base.rb", "lib/cached-models.rb", "lib/cached_models.rb", "setup.rb", "tasks/cached_models_tasks.rake", "test/active_record/associations/has_and_belongs_to_many_association_test.rb", "test/active_record/associations/has_many_association_test.rb", "test/active_record/associations/has_one_association_test.rb", "test/active_record/base_test.rb", "test/fixtures/addresses.yml", "test/fixtures/authors.yml", "test/fixtures/blogs.yml", "test/fixtures/categories.yml", "test/fixtures/categories_posts.yml", "test/fixtures/comments.yml", "test/fixtures/posts.yml", "test/fixtures/tags.yml", "test/models/address.rb", "test/models/author.rb", "test/models/blog.rb", "test/models/category.rb", "test/models/comment.rb", "test/models/post.rb", "test/models/tag.rb", "test/test_helper.rb", "uninstall.rb"]
  s.test_files         = ["test/active_record/associations/has_and_belongs_to_many_association_test.rb", "test/active_record/associations/has_many_association_test.rb", "test/active_record/associations/has_one_association_test.rb", "test/active_record/base_test.rb"]
  s.extra_rdoc_files   = ['README', 'CHANGELOG']
  
  s.add_dependency("activesupport", ["> 2.1.0"])
  s.add_dependency("activerecord",  ["> 2.1.0"])
end