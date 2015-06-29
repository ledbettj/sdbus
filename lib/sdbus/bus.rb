module Sdbus
  class Bus
    attr_reader :ptr

    def initialize(bus_ptr)
      @ptr = bus_ptr
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))
    end

    def service(service)
      Service.new(self, service)
    end

    def self.finalize(ptr)
      proc { Native.sd_bus_unref(ptr) }
    end

    private

    def type_string(params)
      params.map{ |p| type_string_for(p) }.join('')
    end

    def type_string_for(param)
      case param.class
      when String
        's'
      when Fixnum
        'i'
      when Float
        'd'
      when TrueClass, FalseClass
        'b'
      else
        raise ArgumentError, "Don't know type string for '#{param}'"
      end
    end

    def build_varargs(params)
      params.flat_map do |p|
        t = vararg_type(p)
        [t, p]
      end
    end

    def vararg_type(param)
      case param.class
      when String
        :string
      when Fixnum
        :int
      when Float
        :double
      else
        raise ArgumentError, param
      end
    end
  end
end
