require 'rubygems'
require 'rake'

begin
  require 'bundler'
  require 'jeweler'
  require 'rspec/core'
  require 'rspec/core/rake_task'
  require 'reek/rake/task'
  require 'yard'
rescue => e
  puts 'One or more development dependencies are not installed'
  puts 'This project uses bundler as a convenience for setting up the development dependencies'
  puts 'gem install bundler; bundle'
end

Jeweler::Tasks.new do |gem|
  gem.name = 'AXElements'
  gem.homepage = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  gem.license = 'MIT'
  gem.summary = 'A simple layer above the Mac OS X Accessibility APIs'
  gem.description = 'Takes advantage of the new Bridge Support in Mac OS X Lion to'
  gem.email = 'mrada@marketcircle.com'
  gem.authors = ['Mark Rada']
  gem.requirements << 'BridgeSupport 2.0'
  gem.files = ['lib/**/*']
  gem.add_dependency 'activesupport', '~> 3.0.4'
  gem.add_development_dependency 'jeweler',   '~> 1.5.2'
  gem.add_development_dependency 'rspec',     '~> 2.5.0'
#  gem.add_development_dependency 'rcov',      '>= 0'
  gem.add_development_dependency 'reek',      '~> 1.2.8'
  gem.add_development_dependency 'yard',      '~> 0.6.4'
  gem.add_development_dependency 'bluecloth', '~> 2.0.10'
  gem.test_files = Dir.glob('spec/*_spec.rb')
end
Jeweler::RubygemsDotOrgTasks.new

task :test => :spec
task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

#RSpec::Core::RakeTask.new(:rcov) do |spec|
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.rcov = true
#end

Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

YARD::Rake::YardocTask.new

task :garden do
  sh 'yard graph --dependencies --dot="-o docs/images/AX.png -Tpng:quartz"'
end

task :show_off do
  sh 'yard server --reload'
end
