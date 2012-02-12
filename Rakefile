require 'rubygems'

task :default => :test
task :clean   => :clobber


## Documentation

# begin
#   require 'yard'
#   YARD::Rake::YardocTask.new
# rescue LoadError => e
#   $stderr.puts 'It seems as though you do not have yard installed.'
#   command = ENV['RUBY_VERSION'] ? 'rake' : 'sudo macrake'
#   $stderr.puts "You can install it by running `#{command} setup_dev`"
# end

# desc 'Generate Graphviz object graph'
# task :garden => :yard do
#   sh 'yard graph --full --dependencies --dot="-Tpng:quartz" -f docs/images/AX.dot'
# end


## Console

desc 'Start up irb with AXElements loaded'
task :console => :ext do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -Iext -rubygems -rax_elements"
end


## Compilation

require 'rake/compiletask'
Rake::CompileTask.new

desc 'Compile C extensions'
task :ext do
  Dir.chdir 'ext/ax_elements' do
    break if File.exists?('key_coder.bundle') && File.mtime('key_coder.bundle') > File.mtime('key_coder.m')
    ruby 'extconf.rb'
    sh   'make'
  end
end

desc 'Clean temporary files created by the C extension'
task :clobber_ext do
  Dir.chdir 'ext/ax_elements' do
    ['Makefile', 'key_coder.o', 'key_coder.bundle'].each do |file|
      $stdout.puts "rm ext/ax_elements/#{file}"
      rm file
    end
  end
end
task :clobber => :clobber_ext


## Testing

desc 'Open the fixture app'
task :run_fixture => :fixture do
  sh 'open test/fixture/Release/AXElementsTester.app'
end

desc 'Build the test fixture'
task :fixture do
  sh 'cd test/AXElementsTester && xcodebuild'
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs     << 'test' << 'ext'
  t.pattern   = 'test/**/test_*.rb'
  t.ruby_opts = ['-rhelper']
  t.verbose   = true
end
task :test => [:ext, :fixture]


## Gem Packaging

require 'rubygems/package_task'
spec = Gem::Specification.load('AXElements.gemspec')
Gem::PackageTask.new(spec) { }

desc 'Build gem and install it (does not look at dependencies)'
task :install => :gem do
  require 'rubygems/installer'
  Gem::Installer.new("pkg/#{spec.file_name}").install
end


## Setup

desc 'Install dependencies for development'
task :setup_dev do
  require 'rubygems/dependency_installer'
  spec.development_dependencies.each do |dep|
    puts "Installing #{dep.name} (#{dep.requirement})"
    Gem::DependencyInstaller.new.install(dep.name, dep.requirement)
  end
end
