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
      @properties[name] = {type: type, access: access, name: name}
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
        self.object.service.bus.ptr,
        self.object.service.path,
        self.object.path,
        self.name,
        descriptor[:name],
        err,
        reply,
        descriptor[:type],
        :string, value # TODO: handle vararg serialization
      )

      raise BaseError.new(rc) if rc < 0

      nil
    end


    def native_property_get(descriptor)
      err   = FFI::MemoryPointer.new(:uint8, Native::BusError.size)
      reply = FFI::MemoryPointer.new(:pointer)

      rc = Native.sd_bus_get_property(
        self.object.service.bus.ptr,
        self.object.service.path,
        self.object.path,
        self.name,
        descriptor[:name],
        err,
        reply,
        descriptor[:type]
      )

      raise BaseError.new(rc) if rc < 0

      Message.new(reply.read_pointer, descriptor[:type], self.object)
    end

    def native_call(descriptor, args)
      err   = FFI::MemoryPointer.new(:uint8, Native::BusError.size)
      reply = FFI::MemoryPointer.new(:pointer)

      #rc = Native.sd_bus_call_method(
      invoke =[
        self.object.service.bus.ptr,
        self.object.service.path,
        self.object.path,
        self.name,
        descriptor[:name],
        err,
        reply,
        descriptor[:sig][:in],
        *serialize_args(args, descriptor)
      ]
      puts "calling with #{invoke.inspect}"
      rc = Native.sd_bus_call_method(*invoke)
      #)

      if rc < 0
        puts Native::BusError.new(err)[:message]
        raise BaseError.new(rc)
      end

      Message.new(reply.read_pointer, descriptor[:sig][:out], self.object)
    end

    def serialize_args(args, descriptor)
      raise ArgumentError if args.length != descriptor[:in].length

      descriptor[:in].each_with_index.flat_map do |attr, i|
        [ffi_type_from_dbus_type(attr[:type]), args[i]]
      end
    end

    def ffi_type_from_dbus_type(type)
      m = {
        's' => :string,
        'i' => :int32,
        'u' => :uint32,
        'b' => :bool,
        'y' => :uint8,
        'n' => :int16,
        'q' => :uint16,
        'x' => :int64,
        't' => :uint64,
        'd' => :double
      }

      m[type] or raise ArgumentError, "Unknown type for #{type}"
    end

    def titlecase(s)
      s.split('_').map{ |f| f[0].upcase + f[1..-1].downcase }.join('')
    end

  end
end
