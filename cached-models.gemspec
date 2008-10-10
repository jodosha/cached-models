Gem::Specification.new do |s|
  s.name               = "cached-models"
  s.version            = "0.0.2"
  s.date               = "2008-10-10"
  s.summary            = "Transparent caching policy for your models"
  s.author             = "Luca Guidi"
  s.email              = "guidi.luca@gmail.com"
  s.homepage           = "http://lucaguidi.com/pages/cached_models"
  s.description        = "CachedModels provides to your ActiveRecord models a transparent approach to use ActiveSupport caching mechanism."
  s.has_rdoc           = true
  s.rubyforge_project  = %q{cached-models}
  s.files              = ["CHANGELOG", "MIT-LICENSE", "README", "Rakefile", "about.yml", "cached-models.gemspec", "init.rb", "install.rb", "lib/active_record.rb", "lib/active_record/associations.rb", "lib/active_record/associations/association_collection.rb", "lib/active_record/associations/association_proxy.rb", "lib/active_record/associations/has_many_association.rb", "lib/active_record/base.rb", "lib/cached-models.rb", "lib/cached_models.rb", "setup.rb", "tasks/cached_models_tasks.rake", "test/active_record/associations/has_many_association_test.rb", "test/active_record/base_test.rb", "test/fixtures/authors.yml", "test/fixtures/blogs.yml", "test/fixtures/comments.yml", "test/fixtures/posts.yml", "test/fixtures/tags.yml", "test/models/author.rb", "test/models/blog.rb", "test/models/comment.rb", "test/models/post.rb", "test/models/tag.rb", "test/test_helper.rb", "uninstall.rb"]
  s.test_files         = ["test/active_record/associations/has_many_association_test.rb",
    "test/active_record/base_test.rb"]
  s.extra_rdoc_files   = ['README', 'CHANGELOG']
  
  s.add_dependency("activesupport", ["> 2.1.0"])
  s.add_dependency("activerecord",  ["> 2.1.0"])
end