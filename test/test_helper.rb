ENV["RAILS_ENV"] = "test"

require 'test/unit'
require 'rubygems'
require 'active_support'
require 'action_controller'
require 'active_support/test_case'
require 'active_record/fixtures'
require 'action_controller/integration'

# FIXME load path
require File.dirname(__FILE__) + '/../../../../config/environment'
$:.unshift File.dirname(__FILE__) + '/models'
require 'author'
require 'post'

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures"
ActionController::IntegrationTest.fixture_path = Test::Unit::TestCase.fixture_path

class Test::Unit::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all
  
  private
    def cache
      ActiveRecord::Base.rails_cache
    end
end

def uses_mocha(description)
  require 'rubygems'
  require 'mocha'
  yield
rescue LoadError
  $stderr.puts "Skipping #{description} tests. `gem install mocha` and try again."
end
