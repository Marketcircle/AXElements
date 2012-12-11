require 'accessibility/version'

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
  # All hostnames that the system responds to
  #
  # @example
  #
  #   Accessibility::SystemInfo.hostnames 
  #     # => ["ferrous.local", "localhost"]
  #
  # @return [Array<String>]
  def hostnames
    host.names
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
    host.addresses
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
    pinfo.operatingSystemVersionString
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
    pinfo.systemUptime
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
    pinfo.processorCount
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
    pinfo.activeProcessorCount
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
    pinfo.physicalMemory
  end
  alias_method :ram, :total_ram


  private

  def host
    NSHost.currentHost
  end

  def pinfo
    NSProcessInfo.processInfo
  end

end

