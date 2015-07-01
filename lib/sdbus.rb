require 'sdbus/version'
require 'sdbus/type_parser'
require 'sdbus/native'
require 'sdbus/error'
require 'sdbus/bus'
require 'sdbus/message'
require 'sdbus/service'
require 'sdbus/object'
require 'sdbus/interface'

module Sdbus
  def self.system_bus
    ptr = FFI::MemoryPointer.new(:pointer)
    rc = Native.sd_bus_default_system(ptr)
    raise BaseError.new(rc) if rc < 0

    Bus.new(ptr.read_pointer, :system)
  end

  def self.session_bus
    ptr = FFI::MemoryPointer.new(:pointer)
    rc = Native.sd_bus_default_user(ptr)
    raise BaseError.new(rc) if rc < 0

    Bus.new(ptr.read_pointer, :session)
  end
end
