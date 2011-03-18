module AX
require   'logger'

  VERSION   = '0.2.1'
  CODE_NAME = 'Tiger Blood'

  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR

  RUNTIME_DEPENDENCIES = {
    'i18n'          => '0.5.0',
    'activesupport' => '3.0.5'
  }

  # Specify load paths to get around needing rubygems
  $LOAD_PATH.unshift File.absolute_path("#{File.dirname __FILE__}/../../vendor")

end
