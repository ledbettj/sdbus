require 'ffi'

module Sdbus
  class BaseError < StandardError
    attr_reader :code
    def initialize(code)
      @code = -code
      super(LIBC.strerror(@code))
    end

    module LIBC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC

      attach_function :strerror, [:int], :string
    end
  end
end
