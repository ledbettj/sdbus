module Sdbus
  class Bus
    attr_reader :ptr, :type

    def initialize(bus_ptr, type)
      @type = type
      @ptr = bus_ptr
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))
    end

    def service(service)
      Service.new(self, service)
    end

    def services
      dbus_object.call(:list_names)[0].map{ |name| Service.new(self, name) }
    end

    def self.finalize(ptr)
      proc { Native.sd_bus_unref(ptr) }
    end

    def inspect
      "#<#{self.class}:0x#{self.__id__.to_s(16)} @type=#{@type.inspect}>"
    end

    private

    def dbus_object
      @dbus_object ||= service('org.freedesktop.DBus').object('/')
    end
  end
end
