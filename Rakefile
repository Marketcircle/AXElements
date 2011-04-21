task :default => :test

require 'rake/compiletask'
Rake::CompileTask.new do |t|
  t.files = FileList["lib/**/*.rb"]
  t.verbose = true
end

desc 'Clean MacRuby binaries'
task :clean do
  FileList["lib/**/*.rbo"].each do |bin|
    puts rm bin
  end
end

require 'rake/testtask'
test_suites = [:core, :elements, :mouse, :actions]
test_suites.each do |suite|
  namespace :test do
    Rake::TestTask.new(suite) do |t|
      t.libs << 'test'
      t.pattern = "test/#{suite}/*.rb"
      t.ruby_opts = ['-rhelper']
      t.verbose = true
    end
  end
end
desc 'Run all test suites'
task :test => test_suites.map { |suite| "test:#{suite}" }

require 'rubygems'
require 'rubygems/builder'
require 'rubygems/installer'
spec = Gem::Specification.load('AXElements.gemspec')

desc 'Build the gem'
task :build do Gem::Builder.new(spec).build end

desc 'Build the gem and install it'
task :install => :build do Gem::Installer.new(spec.file_name).install end

require 'yard'
YARD::Rake::YardocTask.new

desc 'Generate Graphviz object graph'
task :garden do
  sh 'yard graph --full --dependencies --dot="-Tpng:quartz" -f docs/images/AX.dot'
end

desc 'Start up IRb with AXElements loaded'
task :console do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -rAXElements"
end
