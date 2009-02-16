# RAILS_ENV = "test"
desc 'Run default task (test)'
task :cached_models => 'cached_models:test'

namespace :cached_models do
  desc 'Create CachedModels test database tables and load fixtures'
  task :setup => [ ]

  desc 'Prepare the environment'
  task :environment do
    ActiveRecord::Base.configurations['test'] = { :adapter => 'sqlite3', :file => ':memory:' }
    ENV['SCHEMA'] = File.expand_path(File.join(File.dirname(__FILE__), '..', 'test', 'schema.rb'))
    ENV['FIXTURES_PATH'] = File.expand_path(File.join(File.dirname(__FILE__), '..', 'test', 'fixtures'))
  end

  desc 'Test CachedModels'
  task :test => [ :setup, 'test:all' ]

  namespace :test do
    desc 'Run CachedModels tests'
    Rake::TestTask.new(:all) do |t|
      t.test_files = FileList["#{File.dirname( __FILE__ )}/../test/**/*_test.rb"]
      t.verbose = true
    end
  end
end
