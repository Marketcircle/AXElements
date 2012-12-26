require 'accessibility/version'
require 'accessibility/extras'

##
# Interface for collecting some simple information about the system.
# This information may be useful as diagnostic output when running
# tests, or if you simply need to find the hostname of the machine so
# it can be passed to another process to initiate a connection.
#
# This module extends itself, so all methods are available on the module
# and you will want to use the module as a utility module.
module Accessibility::SystemInfo
  extend self

  ##
  # The name the machine uses for Bonjour
  #
  # @example
  #
  #   Accessibility::SystemInfo.name
  #     # => "ferrous"
  #
  # @return [String]
  def name
    NSHost.currentHost.localizedName
  end

  ##
  # All hostnames that the system responds to
  #
  # @example
  #
  #   Accessibility::SystemInfo.hostnames
  #     # => ["ferrous.local", "localhost"]
  #
  # @return [Array<String>]
  def hostnames
    NSHost.currentHost.names
  end

  ##
  # The first, and likely common, name the system responds to
  #
  # @example
  #
  #   Accessibility::SystemInfo.hostname # => "ferrous.local"
  #
  # @return [Array<String>]
  def hostname
    hostnames.first
  end

  ##
  # All IP addresses the system has interfaces for
  #
  # @example
  #
  #   Accessibility::SystemInfo.addresses
  #     # => ["fe80::6aa8:6dff:fe20:822%en1", "192.168.0.17", "fe80::1%lo0", "127.0.0.1", "::1"]
  #
  # @return [Array<String>]
  def addresses
    NSHost.currentHost.addresses
  end

  ##
  # All IPv4 addresses the system has interfaces for
  #
  # @example
  #
  #   Accessibility::SystemInfo.ipv4_addresses
  #     # => ["192.168.0.17", "127.0.0.1"]
  #
  # @return [Array<String>]
  def ipv4_addresses
    addresses.select { |address| address.match /\./ }
  end

  ##
  # All IPv6 addresses the system has interfaces for
  #
  # @example
  #
  #   Accessibility::SystemInfo.ipv6_addresses
  #     # => ["fe80::6aa8:6dff:fe20:822%en1", "fe80::1%lo0", "::1"]
  #
  # @return [Array<String>]
  def ipv6_addresses
    addresses.select { |address| address.match /:/ }
  end

  ##
  # System model string
  #
  # @example
  #
  #   Accessibility::SystemInfo.model # => "MacBookPro8,2"
  #
  # @return [String]
  def model
    @model ||= `sysctl hw.model`.split.last.chomp
  end

  ##
  # OS X version string
  #
  # @example
  #
  #  Accessibility::SystemInfo.osx_version # => "Version 10.8.2 (Build 12C60)"
  #
  # @return [String]
  def osx_version
    NSProcessInfo.processInfo.operatingSystemVersionString
  end

  ##
  # System uptime, in seconds
  #
  # @example
  #
  #   Accessibility::SystemInfo.uptime # => 22999.76858776
  #
  # @return [Float]
  def uptime
    NSProcessInfo.processInfo.systemUptime
  end

  ##
  # Total number of CPUs the system could use
  #
  # May not be the same as {#num_active_processors}.
  #
  # @example
  #
  #   Accessibility::SystemInfo.num_processors # => 8
  #
  # @return [Fixnum]
  def num_processors
    NSProcessInfo.processInfo.processorCount
  end

  ##
  # Number of CPUs the system current has enabled
  #
  # @example
  #
  #   Accessibility::SystemInfo.num_active_processors # => 8
  #
  # @return [Fixnum]
  def num_active_processors
    NSProcessInfo.processInfo.activeProcessorCount
  end

  ##
  # Total amount of memory for the system, in bytes
  #
  # @example
  #
  #   Accessibility::SystemInfo.total_ram # => 17179869184
  #
  # @return [Fixnum]
  def total_ram
    NSProcessInfo.processInfo.physicalMemory
  end
  alias_method :ram, :total_ram

  ##
  # Return the current state of the battery
  #
  # @example
  #
  #   battery_state # => :charged
  #   # unplug AC cord
  #   battery_state # => :discharging
  #   # plug AC cord back in after several minutes
  #   battery_state # => :charging
  #
  #   # try this method when you have no battery
  #   battery_state # => :not_installed
  #
  # @return [Symbol]
  def battery_state
    Battery.state
  end

  ##
  # Returns the charge percentage of the battery (if present)
  #
  # A special value of `-1.0` is returned if you have no battery.
  #
  # @example
  #
  #   battery_charge_level # => 1.0
  #   # unplug AC cord and wait a couple of minutes
  #   battery_charge_level # => 0.99
  #
  #   # if you have no battery
  #   battery_charge_level # => -1.0
  #
  # @return [Float]
  def battery_charge_level
    Battery.level
  end
  alias_method :battery_level, :battery_charge_level

  ##
  # Return an estimate on the number of minutes until the battery is drained
  #
  # A special value of `0` indicates that the battery is not discharging.
  # You should really only call this after you know that the battery is
  # discharging by calling {#battery_state} and having `:discharging` returned.
  #
  # A special value of `-1` is returned when the estimate is in flux and
  # cannot be accurately estimated.
  #
  # @example
  #
  #   # AC cord plugged in
  #   battery_life_estimate # => 0
  #   # unplug AC cord
  #   battery_life_estimate # => -1
  #   # wait a few minutes
  #   battery_life_estimate # => 423
  #
  # @return [Fixnum]
  def battery_life_estimate
    Battery.time_to_empty
  end

end
