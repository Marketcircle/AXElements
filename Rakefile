require 'rake'
task :default => :test

require 'rake/compiletask'
Rake::CompileTask.new do |t|
  t.files = FileList["lib/**/*.rb"]
  t.verbose = true
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

require 'rubygems'
require 'rubygems/builder'
require 'rubygems/installer'
spec = Gem::Specification.load('AXElements.gemspec')

desc 'Build the gem'
task :build do Gem::Builder.new(spec).build end

desc 'Build the gem and install it'
task :install => :build do Gem::Installer.new(spec.file_name).install end

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
