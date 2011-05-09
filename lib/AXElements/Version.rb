# -*- coding: utf-8 -*-

require   'logger'

##
# A module for all the different accessibility roles.
module AX
  VERSION   = '0.4.1'
  CODE_NAME = 'PokéMaster'

  class << self
    # @todo Move the logger out of the AX module
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR

  EMBEDDED_DEPENDENCIES = {
    'i18n'          => '0.5.0',
    'activesupport' => '3.0.6'
  }

  # Specify load paths to get around needing rubygems
  $LOAD_PATH.unshift File.absolute_path("#{File.dirname __FILE__}/../../vendor")
end
