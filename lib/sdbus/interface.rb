module Sdbus
  class Interface
    attr_reader :object
    attr_reader :name

    def initialize(object, name)
      @object = object
      @name   = name
      @properties = {}
      @methods    = {}
    end

    def add_property(name, type, access)
      @properties[name] = { type: type, access: access, name: name }
    end

    def add_method(name, args)
      args[:name] = name
      @methods[name] = args
    end

    def bus_methods
      @methods.keys
    end

    def bus_method?(m)
      m = m.to_s
      @methods.key?(m) || @methods.key?(titlecase(m))
    end

    def properties
      @properties.keys
    end

    def property?(p)
      p = p.to_s
      @properties.key?(p) || @properties.key?(titlecase(p))
    end

    def get(prop)
      prop = prop.to_s
      descriptor = @properties[prop] || @properties[titlecase(prop)]
      raise ArgumentError unless descriptor[:access] =~ /read/

      reply = native_property_get(descriptor)

      reply[0]
    end

    def set(prop, value)
      prop = prop.to_s
      descriptor = @properties[prop] || @properties[titlecase(prop)]
      raise ArgumentError unless descriptor[:access] =~ /write/

      native_property_set(descriptor, value)
    end

    def call(method, *args)
      method = method.to_s
      descriptor = @methods[method] || @methods[titlecase(method)]

      native_call(descriptor, args)
    end

    private

    # TODO: untested
    def native_property_set(descriptor, value)
      err   = FFI::MemoryPointer.new(:uint8, Native::BusError.size)
      reply = FFI::MemoryPointer.new(:pointer)

      rc = Native.sd_bus_set_property(
        object.service.bus.ptr,
        object.service.path,
        object.path,
        name,
        descriptor[:name],
        err,
        reply,
        descriptor[:type],
        :string, value # TODO: handle vararg serialization
      )

      raise BaseError, rc if rc < 0

      nil
    end

    def native_property_get(descriptor)
      err   = FFI::MemoryPointer.new(:uint8, Native::BusError.size)
      reply = FFI::MemoryPointer.new(:pointer)

      rc = Native.sd_bus_get_property(
        object.service.bus.ptr,
        object.service.path,
        object.path,
        name,
        descriptor[:name],
        err,
        reply,
        descriptor[:type]
      )

      raise BaseError, rc if rc < 0

      Reply.new(object, reply.read_pointer, descriptor[:type])
    end

    def native_call(descriptor, args)
      msg = Message.new(self, descriptor[:name], descriptor[:sig][:in], args)
      msg.send_and_wait(descriptor[:sig][:out])
    end

    def titlecase(s)
      s.split('_').map { |f| f[0].upcase + f[1..-1].downcase }.join('')
    end
  end
end
