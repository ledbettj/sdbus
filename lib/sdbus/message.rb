module Sdbus
  class Message
    attr_reader :object
    attr_reader :type_string

    def initialize(ptr, type_string, object)
      @object      = object
      @ptr         = ptr
      @type_string = type_string
      @values      = []

      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))

      read_fields
    end

    def [](index)
      @values[index]
    end

    private

    def parser
      @parser ||= TypeParser.new
    end

    def types
      @types ||= parser.parse_and_transform(type_string)
    end

    def read_fields
      @values = types.map { |t| read_type(t) }
    end

    def read_type(t)
      case t[:type]
      when :simple  then read_basic(t[:ident])
      when :variant then read_variant
      when :struct  then read_struct(t)
      when :array   then read_array(t)
      when :dict    then read_dict(t)
      else
        raise ArgumentError, "Unknown type descriptor #{t.inspect}"
      end
    end

    def read_struct(t)
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_struct, t[:contains])
      raise BaseError.new(rc) if rc < 0

      results = []

      t[:values].each do |v|
        r = read_type(v)
        Native.sd_bus_message_exit_container(@ptr) and return nil if r.nil?
        results.push(r)
      end

      puts "read struct #{results.inspect}"
      Native.sd_bus_message_exit_container(@ptr)
      results
    end

    def read_variant
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_variant, nil)
      raise BaseError.new(rc) if rc < 0

      str_ptr = FFI::MemoryPointer.new(:pointer)
      type = FFI::MemoryPointer.new(:sd_bus_type)
      rc = Native.sd_bus_message_peek_type(@ptr, type, str_ptr)
      raise BaseError.new(rc) if rc < 0
      puts type.read_string, str_ptr.read_pointer.read_string
      Native.sd_bus_message_exit_container(@ptr)
    end

    def read_array(t)
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_array, t[:contains])
      raise BaseError.new(rc) if rc < 0
      result = []

      loop do
        v = read_type(t[:value])
        break if v.nil?
        result << v
      end

      Native.sd_bus_message_exit_container(@ptr)
      result
    end

    def read_dict(t)
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_array, "{#{t[:contains]}}")
      raise BaseError.new(rc) if rc < 0
      result = {}

      loop do
        Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_dict_entry, t[:contains])
        k = read_type(t[:key])
        Native.sd_bus_message_exit_container(@ptr) and break if k.nil?
        v = read_type(t[:value])
        result[k] = v
        Native.sd_bus_message_exit_container(@ptr)
      end

      Native.sd_bus_message_exit_container(@ptr)
      result
    end

    def read_basic(ch)
      # p is large enough to hold any of the required types.
      p = FFI::MemoryPointer.new(:uint64)

      rc = Native.sd_bus_message_read_basic(@ptr, ch.ord, p)
      return nil if rc.zero?

      raise BaseError.new(rc) if rc < 0

      case ch
      when 'y' then p.read_uint8
      when 'b' then !p.read_uint8.zero?
      when 'n' then p.read_int16
      when 'q' then p.read_uint16
      when 'i' then p.read_int32
      when 'u' then p.read_uint32
      when 'x' then p.read_int64
      when 't' then p.read_uint64
      when 'd' then p.read_double
      when 's', 'g'
        p.read_pointer.read_string
      when 'o'
        Sdbus::Object.new(self.object.service, p.read_pointer.read_string)
#      when 'h'
      else
        raise ArgumentError, "Don't know how to unmarshal #{ch}"
      end
    end

    def self.finalize(ptr)
      proc { Native.sd_bus_message_unref(ptr) }
    end

  end
end
