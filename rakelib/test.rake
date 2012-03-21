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
  [:unit, :integration].each do |group|
    Rake::TestTask.new(group) do |t|
      t.libs     << 'test'
      t.pattern   = "test/#{group}/**/test_*.rb"
      t.ruby_opts = ['-rhelper']
      t.verbose   = true
    end
    task group => [:ext, :fixture]
  end

  desc 'Run tests for the string parser'
  Rake::TestTask.new(:string) do |t|
    t.libs << 'test'
    t.pattern = "test/unit/**/test_string.rb"
    t.ruby_opts = ['-rtest_runner']
    t.verbose = true
  end
  task :string => :ext

  desc 'Run tests under CRuby (where applicable)'
  task :cruby do
    if ENV['RUBY_VERSION'] # rvm is loaded
      puts sh 'rvm 1.9.3 do test:string'
    else
      sh 'rake test:string'
    end
  end
end
