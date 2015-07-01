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

    enum :sd_bus_type, [
      :sd_bus_type_byte,    'y'.ord,
      :sd_bus_type_boolean, 'b'.ord,
      :sd_bus_type_int16,   'n'.ord,
      :sd_bus_type_uint16,  'q'.ord,
      :sd_bus_type_int32,   'i'.ord,
      :sd_bus_type_uint32,  'u'.ord,
      :sd_bus_type_int64,   'x'.ord,
      :sd_bus_type_uint64,  't'.ord,
      :sd_bus_type_double,  'd'.ord,
      :sd_bus_type_string,  's'.ord,
      :sd_bus_type_object_path, 'o'.ord,
      :sd_bus_type_signature,   'g'.ord,
      :sd_bus_type_array,       'a'.ord,
      :sd_bus_type_variant,     'v'.ord,
      :sd_bus_type_struct,      'r'.ord,
      :sd_bus_type_dict_entry,  'e'.ord,
      :sd_bus_type_unix_fd
    ]

    attach_function :sd_bus_default_system, [:pointer], :int
    attach_function :sd_bus_default_user,   [:pointer], :int

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
    attach_function :sd_bus_message_enter_container, [:pointer, :sd_bus_type, :string], :int
    attach_function :sd_bus_message_exit_container, [:pointer], :int

    attach_function :sd_bus_error_free, [:pointer], :void
    attach_function :sd_bus_message_unref, [:pointer], :void
    attach_function :sd_bus_unref, [:pointer], :void
  end
end
