require 'sdbus/version'
require 'sdbus/type_parser'
require 'sdbus/native'
require 'sdbus/error'
require 'sdbus/bus'
require 'sdbus/reply'
require 'sdbus/message'
require 'sdbus/service'
require 'sdbus/object'
require 'sdbus/interface'

module Sdbus
  class << self
    # Returns a new instance of a {Sdbus::Bus} bound to the system bus.
    # @return [Sdbus::Bus]
    def system_bus
      bus(:system)
    end

    # Returns a new instance of a {Sdbus::Bus} bound to the user (session) bus.
    # @return [Sdbus::Bus]
    def user_bus
      bus(:user)
    end

    alias_method :session_bus, :user_bus

    # @private
    def bus(type)
      ptr = FFI::MemoryPointer.new(:pointer)
      rc  = Native.send("sd_bus_default_#{type}", ptr)

      raise BaseError, rc if rc < 0

      Bus.new(ptr.read_pointer, type)
    end
  end
end
