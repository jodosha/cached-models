require File.dirname(__FILE__) + '/active_record'

cache = if defined? Rails
  Rails.cache
else
  require 'active_support'
  configuration = File.dirname(__FILE__) + '/config/cached_models.rb'
  options = eval IO.read(configuration), binding, configuration
  ActiveSupport::Cache.lookup_store(options)
end

ActiveRecord::Base.send(:class_variable_set, :@@rails_cache, cache)
