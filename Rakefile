require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['specs/*_spec.rb']
  t.verbose = true
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# from http://erniemiller.org/2014/02/05/7-lines-every-gems-rakefile-should-have/
task :console do
  require 'irb'
  require 'irb/completion'
  require 'ruse'
  ARGV.clear
  IRB.start
end

task default: [:test, :rubocop]
