require File.dirname(__FILE__) + '/active_record'

ActiveRecord::Base.rails_cache = Rails.cache if defined? Rails
