module Sdbus
  class Message
    def initialize(ptr)
      @ptr = ptr
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))
    end

    def read_string
      p = FFI::MemoryPointer.new(:pointer)
      rc = Native.sd_bus_message_read_basic(@ptr, 's'.ord, p)
      raise BaseError.new(rc) if rc < 0
      p.read_pointer.read_string
    end

    def self.finalize(ptr)
      proc { Native.sd_bus_message_unref(ptr) }
    end

  end
end
