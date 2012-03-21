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
