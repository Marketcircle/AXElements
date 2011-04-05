require   'logger'

##
# A module for all the different accessibility roles.
module AX
  VERSION   = '0.3.0'
  CODE_NAME = 'Tiger Blood'

  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR

  EMBEDDED_DEPENDENCIES = {
    'i18n'          => '0.5.0',
    'activesupport' => '3.0.5'
  }

  # Specify load paths to get around needing rubygems
  $LOAD_PATH.unshift File.absolute_path("#{File.dirname __FILE__}/../../vendor")
end
