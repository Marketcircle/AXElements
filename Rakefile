require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "AXElements"
  gem.homepage = "http://www.marketcircle.com/AXElements"
  gem.license = "MIT"
  gem.summary = %Q{A simple layer above the Mac OS X Accessibility APIs}
  gem.description = %Q{Takes advantage of the new Bridge Support in Mac OS X Lion to}
  gem.email = "mrada@marketcircle.com"
  gem.authors = ["Mark Rada"]
  gem.requirements << 'BridgeSupport 2.0'
  gem.files = ['lib/**/*']
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

#RSpec::Core::RakeTask.new(:rcov) do |spec|
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.rcov = true
#end

task :test => :spec

task :default => :spec

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new

task :garden do
  sh 'yard graph --dependencies --dot="-o docs/images/AX.png -Tpng:quartz"'
end

task :show_off do
  sh 'yard server --reload'
end
