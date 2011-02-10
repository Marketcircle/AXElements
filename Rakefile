require 'rubygems'
require 'bundler'

begin
  Bundler.setup :default, :development
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

task :test    => :spec
task :default => :spec

desc 'Build the gem'
task :build do
  puts sh 'gem build -v AXElements.gemspec'
end

desc 'Build the gem and install it'
task :install => :build do
  puts `gem install -v #{Dir.glob('./AXElements*.gem').sort.reverse.first}`
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'yard'
YARD::Rake::YardocTask.new

desc 'Generate Graphviz object graph'
task :garden do
  sh 'yard graph --dependencies --dot="-o docs/images/AX.png -Tpng:quartz"'
end

desc 'Start the documentation server'
task :show_off do
  sh 'yard server --reload'
end

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end
