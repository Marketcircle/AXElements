# -*- coding: utf-8 -*-

require   'logger'

##
# A module for all the different accessibility roles.
module AX
  VERSION   = '0.4.2'
  CODE_NAME = 'PokéMaster'

  class << self
    # @todo Move the logger out of the AX module
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR
end
