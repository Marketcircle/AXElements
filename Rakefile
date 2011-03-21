require 'rake'
task :default => :test

require 'rake/compiletask'
Rake::CompileTask.new do |t|
  t.files = FileList["lib/**/*.rb"]
  t.verbose = true
end
Rake::CompileTask.new(:compile_deps) do |t|
  t.files = FileList["vendor/**/*.rb"]
end

desc 'Clean MacRuby binaries'
task :clean do
  FileList["lib/**/*.rbo"].each do |bin|
    puts "rm #{bin}"
    rm bin
  end
end

###
# Test

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*.rb'
  t.verbose = true
end


###
# Gem stuff

def build_gem(spec_name)
  require 'rubygems/builder'
  spec = Gem::Specification.load(spec_name)
  Gem::Builder.new(spec).build
end

desc 'Build the gem'
task :build do
  build_gem 'AXElements.gemspec'
end

desc 'Build the gem and install it'
task :install => [:build] do
  gem_name = build_gem 'AXElements.gemspec'
  sh "gem install #{gem_name}"
end


###
# Documentation

# require 'rubygems'
# require 'yard'
# YARD::Rake::YardocTask.new

# namespace :yard do
#   desc 'Generate Graphviz object graph'
#   task :garden do
#     sh 'yard graph --full --dependencies --dot="-Tpng:quartz" -f docs/images/AX.png'
#   end
# end
