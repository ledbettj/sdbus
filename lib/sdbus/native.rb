require 'ffi'

module Sdbus
  module Native
    extend FFI::Library
    ffi_lib 'libsystemd'

    class BusError < FFI::Struct
      layout :name,       :string,
             :message,    :string,
             :_need_free, :int
    end

    attach_function :sd_bus_default_system, [:pointer], :int

    attach_function :sd_bus_call_method, [
      :pointer, # bus
      :string,  # destination
      :string,  # path
      :string,  # iface
      :string,  # member
      :pointer, # error
      :pointer, # reply
      :string,  # signature
      :varargs
    ], :int

    attach_function :sd_bus_set_property, [
      :pointer, # bus
      :string,  # destination
      :string,  # path
      :string,  # iface
      :string,  # member
      :pointer, # error
      :pointer, # reply
      :string,  # signature
      :varargs
    ], :int


    attach_function :sd_bus_get_property, [
      :pointer, # bus
      :string,  # destination
      :string,  # path
      :string,  # iface
      :string,  # member
      :pointer, # error
      :pointer, # reply
      :string   # signature
    ], :int

    attach_function :sd_bus_message_read_basic, [:pointer, :char, :pointer], :int

    attach_function :sd_bus_error_free, [:pointer], :void
    attach_function :sd_bus_message_unref, [:pointer], :void
    attach_function :sd_bus_unref, [:pointer], :void
  end
end
