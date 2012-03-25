require 'rubygems'

task :default => :test

desc 'Remove all generated files'
task :clean   => :clobber
desc 'Remove all generated files'
task :clobber => 'clobber:ext'

desc 'Compile C extensions'
task :ext => 'ext:key_coder'

desc 'Run all tests'
task :test => ['test:unit', 'test:integration', 'test:cruby']
