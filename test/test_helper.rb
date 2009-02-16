ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'test/unit'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))
require 'active_record/fixtures'

$:.unshift File.dirname(__FILE__) + '/models'
require 'author'
require 'post'

silence_warnings do
  cache = ActiveSupport::Cache.lookup_store :mem_cache_store
  Object.const_set "RAILS_CACHE", cache
  ActiveRecord::Base.rails_cache = cache
end

def load_schema
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
  ActiveRecord::Schema.verbose = false

  ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :dbfile => ':memory:'
  load(File.dirname(__FILE__) + "/schema.rb")
  fixtures = %w( addresses authors blogs posts categories categories_posts comments tags )
  fixtures.each { |f| Fixtures.create_fixtures(ActiveSupport::TestCase.fixture_path, f) }
end

begin
  require 'memcache'
  MemCache.new('localhost').stats
rescue MemCache::MemCacheError
  $stderr.puts "[WARNING] Memcache is not running!"
end

module WillPaginate #:nodoc:
  def paginate(*args)
    options = args.extract_options!
    current_page, per_page = options[:page], options[:per_page]
    offset = (current_page - 1) * per_page

    count_options = options.except :page, :per_page
    find_options = count_options.except(:count).update(:offset => offset, :limit => per_page) 

    args << find_options
    @reflection.klass.find(*args)
  end
end

module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy #:nodoc:
      include WillPaginate
    end
  end
end

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.fixture_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all
  
  def setup
    load_schema
  end
  
  # Assert the given condition is false
  def assert_false(condition, message = nil)
    assert !condition, message
  end

  private
    def cache
      ActiveRecord::Base.rails_cache
    end

    def create_post(options = {})
      Post.new({ :author_id => 1,
        :title => 'CachedModels',
        :text => 'Introduction to CachedModels plugin',
        :published_at => 1.week.ago }.merge(options))
    end

    def post_options(options = {})
      { :blog_id => blogs(:weblog).id,
        :title => "Cached models review",
        :text => "Cached models review..",
        :published_at => 1.week.ago }.merge(options)
    end    
end

ActionController::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path

def uses_mocha(description)
  require 'rubygems'
  require 'mocha'
  yield
rescue LoadError
  $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
end

if ENV['SKIP_MOCHA'] == 'true'
  class Object
    def expects(*args)
      self
    end

    def method_missing(method_name, *args, &block)
    end
  end

  class NilClass
    def method_missing(method_name, *args, &block)
    end
  end
end
