require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

version = '0.0.2'
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

desc 'Build and install the gem (useful for development purposes).'
task :install do
  system "gem build cached-models.gemspec"
  system "sudo gem uninstall cached-models"
  system "sudo gem install --local --no-rdoc --no-ri cached-models-#{version}.gem"
  system "rm cached-models-*.gem"
end

desc 'Build and prepare files for release.'
task :dist => :clean do
  require 'cached-models'
  system "gem build cached-models.gemspec"
  system "cd .. && tar -czf cached-models-#{version}.tar.gz cached_models"
  system "cd .. && tar -cjf cached-models-#{version}.tar.bz2 cached_models"
  system "cd .. && mv cached-models-* cached_models"
end

desc 'Clean the working copy from release files.'
task :clean do
  system "rm cached-models-#{version}.gem"     if File.exist? "cached-models-#{version}.gem"
  system "rm cached-models-#{version}.tar.gz"  if File.exist? "cached-models-#{version}.tar.gz"
  system "rm cached-models-#{version}.tar.bz2" if File.exist? "cached-models-#{version}.tar.bz2"
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
