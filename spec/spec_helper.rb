$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "cached-models"
require "factory_girl"
require "memcache"

ActiveRecord::Base.send(:class_variable_set, :@@associations_cache, ActiveSupport::Cache.lookup_store(:mem_cache_store))
ActiveRecord::Base.establish_connection :adapter => "sqlite3", :dbfile => ":memory:"
ActiveRecord::Schema.verbose = false
load(File.dirname(__FILE__) + "/schema.rb")

Dir["#{File.dirname(__FILE__)}/models/**/*.rb"].each { |model| require model }

begin
  MemCache.new('localhost').stats
rescue MemCache::MemCacheError
  $stderr.puts "[WARNING] Memcache is not running!"
end
