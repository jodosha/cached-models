$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "cached-models"
require "memcache"

ActiveRecord::Base.send(:class_variable_set, :@@associations_cache, ActiveSupport::Cache.lookup_store(:mem_cache_store))

def cache
  ActiveRecord::Base.associations_cache
end
