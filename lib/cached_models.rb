activerecord_path = "#{File.dirname(__FILE__)}/../vendor/activerecord/lib"
if File.directory?(activerecord_path)
  $:.unshift(activerecord_path)
else
  require "rubygems"
end

require "active_record"
require "lib/activerecord/lib/active_record"