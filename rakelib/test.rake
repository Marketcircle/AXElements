desc 'Start up irb with AXElements loaded'
task :console => :ext do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -rubygems -rax_elements"
end

desc 'Open the fixture app'
task :run_fixture => :fixture do
  sh 'open test/fixture/Release/AXElementsTester.app'
end

desc 'Build the test fixture'
task :fixture do
  sh 'cd test/AXElementsTester && xcodebuild'
end

desc 'Remove the built fixture app'
task :clobber_fixture do
  $stdout.puts 'rm -rf test/fixture'
  rm_rf 'test/fixture'
end
task :clobber => :clobber_fixture

require 'rake/testtask'
namespace :test do
  Rake::TestTask.new(:sanity) do |t|
    t.libs   << '.'
    t.pattern = "test/sanity/**/test_*.rb"
  end
  task :sanity => [:ext, :fixture]

  Rake::TestTask.new(:integration) do |t|
    t.libs   << '.'
    t.pattern = "test/integration/**/test_*.rb"
  end
  task :integration => [:ext, :fixture]

  desc 'Run tests for the string parser'
  Rake::TestTask.new(:string) do |t|
    t.libs   << '.'
    t.pattern = "test/sanity/accessibility/test_string.rb"
  end
  task :string => :ext
end
