module Sdbus
  class Message
    def initialize(ptr, type_string = nil)
      @ptr = ptr
      @type_string = type_string
      @values = []
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))

      read_fields unless type_string.nil?
    end

    def [](index)
      @values[index]
    end

    private

    def parser
      @parser ||= TypeParser.new
    end

    def types
      @types ||= parser.parse_and_transform(@type_string)
    end

    def read_fields
      types.each do |t|
        @values.push(read_type(t))
      end
    end

    def read_type(t)
      puts "Read type #{t.inspect}"
      case t[:type]
      when :simple
        read_basic(t[:ident])
#      when :variant
#       read_variant
      when :struct
        read_struct(t)
      when :array
        read_array(t)
      when :dict
        read_dict(t)
      else
        raise ArgumentError, "Unknown type descriptor #{t.inspect}"
      end
    end

    def read_struct(t)
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_struct, 'usssoo')
      raise BaseError.new(rc) if rc < 0
      results = []
      t[:values].each do |v|
        r = read_type(v)
        return nil if r.nil?
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
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_array, nil)
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
      rc = Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_array, nil)
      raise BaseError.new(rc) if rc < 0
      result = {}

      loop do
        Native.sd_bus_message_enter_container(@ptr, :sd_bus_type_dict_entry, nil)
        k = read_type(t[:key])
        break if k.nil?
        v = read_type(t[:value])
        result[k] = v
        Native.sd_bus_message_exit_container(@ptr)
      end

      Native.sd_bus_message_exit_container(@ptr)
      result
    end

    def read_basic(ch)
#      puts "calling read_basic #{ch}"
      p = FFI::MemoryPointer.new(:pointer)
      rc = Native.sd_bus_message_read_basic(@ptr, ch.ord, p)
      raise BaseError.new(rc) if rc < 0
      deref = p.read_pointer
      return nil if deref.null?
      case ch
      when 'i'
        deref.read_int32
      when 'u'
        deref.read_uint32
      when 's', 'o', 'g'
        deref.read_string
      end
    end

    def self.finalize(ptr)
      proc { Native.sd_bus_message_unref(ptr) }
    end

  end
end
