require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

repositories = %w( origin rubyforge )

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the cached_models plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the cached_models plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'CachedModels'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Show the file list for the gemspec file'
task :files do
  puts "Files:\n #{Dir['**/*'].reject {|f| File.directory?(f)}.sort.inspect}"
  puts "Test files:\n #{Dir['test/**/*_test.rb'].reject {|f| File.directory?(f)}.sort.inspect}"
end

namespace :git do
  desc 'Push local Git commits to all remote centralized repositories.'
  task :push do
    repositories.each do |repository|
      puts "Pushing #{repository}...\n"
      system "git push #{repository} master"
    end
  end
  
  desc 'Perform a git-tag'
  task :tag do
    puts "Please enter the tag name: "
    tag_name = STDIN.gets.chomp
    exit(1) if tag_name.nil? or tag_name.empty?
    system %(git tag -s #{tag_name} -m "Tagged #{tag_name}")
  end
  
  desc 'Push all the tags to remote centralized repositories.'
  task :push_tags do
    repositories.each do |repository|
      puts "Pushing tags to #{repository}...\n"
      system "git push --tags #{repository}"
    end
  end
end
