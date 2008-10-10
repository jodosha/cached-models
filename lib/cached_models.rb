require 'activesupport' unless defined? Rails
require File.dirname(__FILE__) + '/activerecord/lib/active_record'

ActiveRecord::Base.rails_cache = Rails.cache if defined? Rails
