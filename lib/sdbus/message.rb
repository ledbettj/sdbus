module Sdbus
  class Message
    attr_reader :object
    attr_reader :type_string

    def initialize(iface, method, type_string, params)
      @object      = iface.object
      @type_string = type_string
      p = FFI::MemoryPointer.new(:pointer)

      rc = Native.sd_bus_message_new_method_call(
        iface.object.service.bus.ptr,
        p,
        iface.object.service.path,
        iface.object.path,
        iface.name,
        method
      )
      raise BaseError.new(rc) if rc < 0
      @ptr = p.read_pointer

      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))

      serialize_params(params)
    end

    def send_and_wait(out_type_str)
      err   = FFI::MemoryPointer.new(:uint8, Native::BusError.size)
      reply = FFI::MemoryPointer.new(:pointer)

      rc = Native.sd_bus_call(object.service.bus.ptr, @ptr, -1, err, reply)

      if rc < 0
        e = Native::BusError.new(err)
        puts e[:message]
        raise BaseError.new(rc)
      end

      Reply.new(self, reply.read_pointer, out_type_str)
    end

    private

    def parser
      @parser ||= TypeParser.new
    end

    def types
      @types ||= parser.parse_and_transform(type_string)
    end

    def serialize_params(params)
      types.each_with_index do |t, i|
        serialize_param(t, params[i])
      end
    end

    def serialize_param(t, value)
      case t[:type]
      when :simple  then serialize_basic(t[:ident], value)
      when :array   then serialize_array(t, value)
      when :dict    then serialize_dict(t, value)
      when :struct  then serialize_struct(t, value)
#      when :variant then
      end
    end

    def serialize_array(t, value)
      rc = Native.sd_bus_message_open_container(@ptr, :sd_bus_type_array, t[:contains])
      raise BaseError.new(rc) if rc < 0

      value.each{ |v| serialize_param(t[:value], v) }

      rc = Native.sd_bus_message_close_container(@ptr)
      raise BaseError.new(rc) if rc < 0
    end

    def serialize_dict(t, value)
      rc = Native.sd_bus_message_open_container(@ptr, :sd_bus_type_array, "{#{t[:contains]}}")
      raise BaseError.new(rc) if rc < 0

      value.each{ |k, v| serialize_dict_entry(t, k, v) }

      rc = Native.sd_bus_message_close_container(@ptr)
      raise BaseError.new(rc) if rc < 0
    end

    def serialize_dict_entry(t, key, value)
      rc = Native.sd_bus_message_open_container(@ptr, :sd_bus_type_dict_entry, t[:contains])
      raise BaseError.new(rc) if rc < 0

      serialize_param(t[:key])
      serialize_param(t[:value])

      rc = Native.sd_bus_message_close_container(@ptr)
      raise BaseError.new(rc) if rc < 0
    end

    def serialize_struct(t, value)
      rc = Native.sd_bus_message_open_container(@ptr, :sd_bus_type_struct, t[:contains])
      raise BaseError.new(rc) if rc < 0

      t[:values].each_with_index{ |item, i| serialize_param(item, value[i]) }

      rc = Native.sd_bus_message_close_container(@ptr)
      raise BaseError.new(rc) if rc < 0
    end

    def serialize_basic(ch, value)
      va_type = case ch
                when 'y' then :uint8
                when 'b' then :uint8
                when 'n' then :int16
                when 'q' then :uint16
                when 'i' then :int32
                when 'u' then :uint32
                when 'x' then :int64
                when 't' then :uint64
                when 'd' then :double
                when 's', 'o', 'g' then :string
                else
                  raise ArgumentError, "Don't know how to marshal #{ch}"
                end

      value_ptr = if ch == 'b'
                    FFI::MemoryPointer.new(:uint8, 1).tap{ |p| p.write_uint8(value ? 1 : 0) }
                  elsif ch == 's' || ch == 'g'
                    FFI::MemoryPointer.from_string(value)
                  elsif ch == 'o'
                    FFI::MemoryPointer.from_string(value.path)
                  else
                    value_ptr = FFI::MemoryPointer.new(va_type, 1).tap { |p| p.send("write_#{va_type}", value) }
                  end

      rc = Native.sd_bus_message_append_basic(@ptr, ch.ord, value_ptr)
      raise BaseError.new(rc) if rc < 0
    end

    def self.finalize(ptr)
      proc { Native.sd_bus_message_unref(ptr) }
    end
  end
end
